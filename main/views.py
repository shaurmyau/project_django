from django.contrib.auth import login, logout, authenticate
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import UserCreationForm
from django.shortcuts import render, redirect, get_object_or_404
from django import forms
from django.contrib.auth.models import User
from django.db import models
from django.views.generic import ListView, DetailView, CreateView, DeleteView, UpdateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Q
from django.utils import timezone
from .models import Card, UserTransactionView, Balance, Transactions, Budget, Category, News
from datetime import timedelta
from django.contrib import messages
from django.urls import reverse_lazy
from django.db.models import Sum
from .forms import TransactionForm
from django.views import View

class BudgetListView(LoginRequiredMixin, ListView):
    model = Budget
    template_name = 'budget/budget_list.html'
    context_object_name = 'budgets'
    
    def get_queryset(self):
        # Получаем бюджеты текущего пользователя
        return Budget.objects.filter(bal__owner=self.request.user).select_related('category', 'bal')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        # Начало текущего месяца
        current_month = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        # Для каждого бюджета считаем текущие траты
        for budget in context['budgets']:
            # Сумма расходов по этой категории за текущий месяц
            monthly_spent = budget.bal.transactions_set.filter(
                category=budget.category,
                dir=False,  # Только расходы
                created_at__gte=current_month
            ).aggregate(total=Sum('amount'))['total'] or 0
            
            budget.current_spent = monthly_spent
            budget.remaining = budget.limit - monthly_spent
            budget.percentage = (monthly_spent / budget.limit * 100) if budget.limit > 0 else 0
        
        # Все категории для формы создания
        context['categories'] = Category.objects.all()
        
        # Все балансы пользователя
        context['balances'] = Balance.objects.filter(owner=self.request.user)
        
        # Статистика
        total_limit = sum(b.limit for b in context['budgets'])
        total_spent = sum(b.current_spent for b in context['budgets'])
        
        context['total_limit'] = total_limit
        context['total_spent'] = total_spent
        context['total_remaining'] = total_limit - total_spent
        context['overall_percentage'] = (total_spent / total_limit * 100) if total_limit > 0 else 0
        
        return context

class BudgetCreateView(LoginRequiredMixin, CreateView):
    model = Budget
    template_name = 'budget/budget_form.html'
    fields = ['bal', 'category', 'limit']
    success_url = reverse_lazy('budget-list')
    
    def get_initial(self):
        """Устанавливаем начальные значения"""
        initial = super().get_initial()
        # Можно установить первый баланс пользователя по умолчанию
        user_balance = Balance.objects.filter(owner=self.request.user).first()
        if user_balance:
            initial['bal'] = user_balance
        return initial
    
    def get_form(self, form_class=None):
        form = super().get_form(form_class)
        form.fields['bal'].queryset = Balance.objects.filter(owner=self.request.user)
        return form    

    def form_valid(self, form):
        # Убедимся, что пользователь создает бюджет только для своего баланса
        balance = form.cleaned_data['bal']
        if balance.owner != self.request.user:
            form.add_error('bal', 'Вы не можете создавать бюджет для чужого баланса')
            return self.form_invalid(form)
        
        # Проверка на дубликат
        existing = Budget.objects.filter(
            bal=balance,
            category=form.cleaned_data['category']
        ).exists()
        
        if existing:
            form.add_error(None, 'Бюджет для этой категории уже существует')
            return self.form_invalid(form)
        
        messages.success(self.request, 'Бюджет успешно создан')
        return super().form_valid(form)
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['categories'] = Category.objects.all()
        context['balances'] = Balance.objects.filter(owner=self.request.user)
        return context

class BudgetUpdateView(LoginRequiredMixin, UpdateView):
    model = Budget
    template_name = 'budget/budget_form.html'
    fields = ['limit']
    success_url = reverse_lazy('budget-list')
    
    def get_queryset(self):
        # Ограничиваем доступ только к своим бюджетам
        return Budget.objects.filter(bal__owner=self.request.user)
    
    def form_valid(self, form):
        messages.success(self.request, 'Бюджет успешно обновлен')
        return super().form_valid(form)

class BudgetDeleteView(LoginRequiredMixin, DeleteView):
    model = Budget
    template_name = 'budget/budget_confirm_delete.html'
    success_url = reverse_lazy('budget-list')
    
    def get_queryset(self):
        # Ограничиваем доступ только к своим бюджетам
        return Budget.objects.filter(bal__owner=self.request.user)
    
    def delete(self, request, *args, **kwargs):
        messages.success(request, 'Бюджет успешно удален')
        return super().delete(request, *args, **kwargs)

class CustomUserCreationForm(UserCreationForm):
    email = forms.EmailField(
        required=True,
        widget=forms.EmailInput(attrs={'class': 'form-control', 'placeholder': 'Email'})
    )
    
    class Meta:
        model = User
        fields = ("username", "email", "password1", "password2")
    
    def save(self, commit=True):
        user = super().save(commit=False)
        user.email = self.cleaned_data["email"]  # ← ВАЖНО: сохраняем email
        if commit:
            user.save()
        return user

def register_view(request):
    """Обработка регистрации новых пользователей"""
    if request.method == 'POST':
        # Создание формы с данными из запроса
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            # Сохранение пользователя в базу данных
            user = form.save()
            # Автоматический вход после регистрации
            login(request, user)
            return redirect('account')
    else:
        # Показ пустой формы для GET-запроса
        form = CustomUserCreationForm()
    
    return render(request, 'registration/register.html', {'form': form})

def login_view(request):
    """Обработка входа пользователей в систему"""
    if request.method == 'POST':
        # Получение данных из формы 
        username = request.POST['username']
        password = request.POST['password']
        # Проверка подлинности пользователя
        user = authenticate(request, username=username, password=password,)
        
        if user is not None:
            # Успешная аутентификация - вход в систему
            login(request, user)
            return redirect('account')
        else:
            # Ошибка аутентификации
            messages.error(request, 'Неправильный логин или пароль')
            return render(request, 'registration/login.html')
    
    return render(request, 'registration/login.html')

def logout_view(request):
    """Выход пользователя из системы"""
    logout(request)
    return redirect('home')

def home(request):
    return render(request, 'main/home.html')

@login_required
def account(request):
    context = {'title': 'Главная страница'}
    return render(request, 'main/account.html', context)

@login_required
def budget(request):
    context = {'title': 'Контроль бюджета'}
    return render(request, 'main/budget.html', context)

@login_required
def stats(request):
    context = {'title': 'Статистика по картам'}
    return render(request, 'main/stats.html', context)

def news(request):
    context = {'title': 'Здесь будут храниться новости'}
    return render(request, 'main/news.html', context)

# Главная страница - список карт пользователя
class CardListView(LoginRequiredMixin, ListView):
    model = Card
    template_name = 'main/account.html'
    context_object_name = 'cards'
    
    def get_queryset(self):
        # Получаем только карты текущего пользователя
        return Card.objects.filter(bal__owner=self.request.user).select_related('bal')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        total_balance = Balance.objects.filter(owner=self.request.user).aggregate(
            total=models.Sum('bal')
        )['total'] or 0
        context['total_balance'] = total_balance
        context['cards_count'] = self.get_queryset().count()
        context['balances'] = Balance.objects.filter(owner = self.request.user)
        return context

# Детальная информация о карте

class BalanceDetailView(LoginRequiredMixin, DetailView):
    model = Balance
    template_name = 'main/balance_detail.html'
    context_object_name = 'balance'
    
    def get_queryset(self):
        # Ограничиваем доступ только к своим картам
        return Balance.objects.filter(owner=self.request.user)
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        bal = self.object
        # Последние 5 транзакций по этой карте
        recent_transactions = Transactions.objects.filter(
            bal=bal
        ).select_related('category').order_by('-created_at')[:5]
        context['recent_transactions'] = recent_transactions
        
        return context
    
class CardDetailView(LoginRequiredMixin, DetailView):
    model = Card
    template_name = 'main/card_detail.html'
    context_object_name = 'card'
    
    def get_queryset(self):
        # Ограничиваем доступ только к своим картам
        return Card.objects.filter(bal__owner=self.request.user)
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        card = self.object
        
        # Добавляем дополнительную информацию
        context['expiration_date'] = card.expiration_date
        context['days_until_expiration'] = (card.expiration_date - timezone.now()).days
        
        # Статус карты
        if context['days_until_expiration'] > 90:
            context['card_status'] = 'active'
            context['status_text'] = 'Активна'
        elif context['days_until_expiration'] > 0:
            context['card_status'] = 'expiring'
            context['status_text'] = 'Скоро истекает'
        else:
            context['card_status'] = 'expired'
            context['status_text'] = 'Просрочена'
        
        # Последние 5 транзакций по этой карте
        recent_transactions = Transactions.objects.filter(
            bal=card.bal
        ).select_related('category').order_by('-created_at')[:5]
        context['recent_transactions'] = recent_transactions
        
        return context

# Страница транзакций с фильтрами
class TransactionListView(LoginRequiredMixin, ListView):
    model = UserTransactionView
    template_name = 'main/transactions.html'
    context_object_name = 'transactions'
    paginate_by = 20
    
    def get_queryset(self):
        queryset = UserTransactionView.objects.all()
        queryset = queryset.filter(
            card_number__in=Card.objects.filter(
                bal__owner=self.request.user
            ).values('number')
)
        
        # Фильтр по дате
        date_filter = self.request.GET.get('date_filter', 'all')
        today = timezone.now().date()
        
        if date_filter == 'today':
            queryset = queryset.filter(created_at__date=today)
        elif date_filter == 'week':
            week_ago = today - timedelta(days=7)
            queryset = queryset.filter(created_at__date__gte=week_ago)
        elif date_filter == 'month':
            month_ago = today.replace(day=1)
            queryset = queryset.filter(created_at__date__gte=month_ago)
        
        # Фильтр по типу (доход/расход)
        type_filter = self.request.GET.get('type_filter')
        if type_filter:
            if type_filter == 'income':
                queryset = queryset.filter(amount_direction=True)
            elif type_filter == 'expense':
                queryset = queryset.filter(amount_direction=False)
        
        # Поиск по категории
        search_query = self.request.GET.get('search')
        if search_query:
            print(search_query)
            queryset = queryset.filter(
                Q(category_name__icontains=search_query)
            )
        
        card_search = self.request.GET.get('card_search')
        if card_search:
            print(card_search)
            queryset = queryset.filter(
                Q(card_number__icontains=card_search)
            )
        
        return queryset.order_by('-created_at')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        queryset = self.get_queryset()
        
        # Добавляем параметры фильтров для шаблона
        context['date_filter'] = self.request.GET.get('date_filter', 'all')
        context['type_filter'] = self.request.GET.get('type_filter', '')
        context['search_query'] = self.request.GET.get('search', '')
        context['card_search'] = self.request.GET.get('card_search', '')
        
        # Статистика
        context['total_count'] = queryset.count()
        
        # Сумма доходов и расходов
        income_agg = queryset.filter(amount_direction=True).aggregate(
            total=Sum('amount')
        )
        expense_agg = queryset.filter(amount_direction=False).aggregate(
            total=Sum('amount')
        )
        
        income_total = income_agg.get('total') or 0
        expense_total = expense_agg.get('total') or 0
        
        context['income_total'] = income_total
        context['expense_total'] = expense_total
        context['balance'] = income_total - expense_total
        
        return context
    
class CreateTransactionView(LoginRequiredMixin, View):
    
    def get(self, request):
        # Получаем только счета текущего пользователя
        user_balances = Balance.objects.filter(owner=request.user)
        history = Transactions.history.all()
        for record in history:
            print(record)
        form = TransactionForm()
        # Фильтруем счета только для текущего пользователя
        form.fields['bal'].queryset = user_balances
        form.fields['category'].queryset = Category.objects.all()
        
        return render(request, 'main/create_transaction.html', {
            'form': form,
            'has_balances': True
        })
    
    def post(self, request):
        user_balances = Balance.objects.filter(owner=request.user)
        
        form = TransactionForm(request.POST)
        form.fields['bal'].queryset = user_balances
        form.fields['category'].queryset = Category.objects.all()
        
        if form.is_valid():
            # Проверяем, что счет принадлежит текущему пользователю
            balance = form.cleaned_data['bal']
            if balance.owner != request.user:
                messages.error(request, 'Вы не можете использовать чужой счет')
                return render(request, 'main/create_transaction.html', {
                    'form': form,
                    'has_balances': True
                })
            
            try:
                transaction = form.save()
                messages.success(request, 'Транзакция успешно создана!')
                return redirect('create_transaction')
            except Exception as e:
                messages.error(request, f'Ошибка при создании транзакции: {str(e)}')
        
        return render(request, 'main/create_transaction.html', {
            'form': form,
            'has_balances': True
        })
        
class NewsListView(ListView):
    model = News
    template_name = 'main/news_list.html'
    context_object_name = 'news_list'
    paginate_by = 10
    
    def get_queryset(self):
        # Показываем только опубликованные новости
        return News.objects.filter(is_published=True).order_by('-created_at')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['title'] = 'Новости'
        return context

# Детальный просмотр новости
class NewsDetailView(DetailView):
    model = News
    template_name = 'main/news_detail.html'
    context_object_name = 'news'
    
    def get_queryset(self):
        # Для детального просмотра показываем даже неопубликованные
        # если пользователь суперпользователь
        if self.request.user.is_superuser:
            return News.objects.all()
        return News.objects.filter(is_published=True)
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['title'] = self.object.title
        return context