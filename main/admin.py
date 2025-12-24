from django.contrib import admin
from django.utils.html import format_html
from django.utils import timezone
from datetime import timedelta
from .models import Category, Balance, Card, Transactions, Budget, UserTransactionView, News
from django.db import models

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'name')
    list_display_links = ('name',)
    search_fields = ('name',)
    ordering = ('name',)

@admin.register(Balance)
class BalanceAdmin(admin.ModelAdmin):
    list_display = ('id', 'owner_info', 'bal', 'cards_count')
    list_display_links = ('id',)
    list_filter = ('owner',)
    search_fields = ('owner__username', 'owner__email')
    ordering = ('-id',)
    
    def owner_info(self, obj):
        return f"{obj.owner.username} ({obj.owner.email})"
    owner_info.short_description = 'Владелец'
    
    def cards_count(self, obj):
        count = Card.objects.filter(bal=obj).count()
        return format_html('<span style="color: {};">{}</span>', 
                          'green' if count > 0 else 'red', count)
    cards_count.short_description = 'Карт'

@admin.register(Card)
class CardAdmin(admin.ModelAdmin):
    list_display = ('number', 'owner_info', 'balance_info', 'cvv', 'date', 'expiration_status')
    list_display_links = ('number',)
    list_filter = ('bal__owner', 'date')
    search_fields = ('number', 'bal__owner__username')
    readonly_fields = ('number', 'CVV', 'date')
    ordering = ('-date',)
    
    def owner_info(self, obj):
        return obj.bal.owner.username
    owner_info.short_description = 'Владелец'
    
    def balance_info(self, obj):
        return f"{obj.bal.bal} руб."
    balance_info.short_description = 'Баланс'
    
    def cvv(self, obj):
        return obj.CVV
    cvv.short_description = 'CVV'
    
    def expiration_status(self, obj):
        exp_date = obj.expiration_date
        remaining = (exp_date - timezone.now()).days
        
        if remaining > 90:
            color = 'green'
            status = f"Действует до {exp_date.strftime('%d.%m.%Y')}"
        elif remaining > 0:
            color = 'orange'
            status = f"Истекает через {remaining} дн."
        else:
            color = 'red'
            status = "Просрочена"
        
        return format_html('<span style="color: {};">{}</span>', color, status)
    expiration_status.short_description = 'Статус'

class IsExpiredFilter(admin.SimpleListFilter):
    title = 'Просроченные транзакции'
    parameter_name = 'is_expired'
    
    def lookups(self, request, model_admin):
        return (
            ('yes', 'Просроченные'),
            ('no', 'Активные'),
        )
    
    def queryset(self, request, queryset):
        month_ago = timezone.now() - timedelta(days=30)
        if self.value() == 'yes':
            return queryset.filter(created_at__lt=month_ago)
        if self.value() == 'no':
            return queryset.filter(created_at__gte=month_ago)

@admin.register(Transactions)
class TransactionsAdmin(admin.ModelAdmin):
    list_display = ('id', 'balance_info', 'amount_display', 'category', 'direction_display', 'created_at')
    list_display_links = ('id',)
    list_filter = ('dir', 'category', 'created_at', IsExpiredFilter)
    search_fields = ('bal__owner__username', 'category__name')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)
    date_hierarchy = 'created_at'
    
    def balance_info(self, obj):
        return f"{obj.bal.owner.username} ({obj.bal.bal} руб.)"
    balance_info.short_description = 'Счёт'
    
    def amount_display(self, obj):
        color = 'green' if obj.dir else 'red'
        sign = '+' if obj.dir else '-'
        return format_html('<span style="color: {}; font-weight: bold;">{}{} руб.</span>', 
                          color, sign, obj.amount)
    amount_display.short_description = 'Сумма'
    
    def direction_display(self, obj):
        return format_html(
            '<span style="color: {};">{}</span>',
            'green' if obj.dir else 'red',
            'Доход' if obj.dir else 'Расход'
        )
    direction_display.short_description = 'Направление'
    
    fieldsets = (
        ('Основная информация', {
            'fields': ('bal', 'amount', 'category', 'dir')
        }),
        ('Дополнительно', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )

@admin.register(Budget)
class BudgetAdmin(admin.ModelAdmin):
    list_display = ('id', 'balance_info', 'category', 'limit', 'current_spending', 'status')
    list_display_links = ('id',)
    list_filter = ('category', 'bal__owner')
    search_fields = ('bal__owner__username', 'category__name')
    ordering = ('-id',)
    
    def balance_info(self, obj):
        return obj.bal.owner.username
    balance_info.short_description = 'Владелец'
    
    def current_spending(self, obj):
        month_start = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        spending = Transactions.objects.filter(
            bal=obj.bal,
            category=obj.category,
            dir=False,
            created_at__gte=month_start
        ).aggregate(total=models.Sum('amount'))['total'] or 0
        return f"{spending} руб."
    current_spending.short_description = 'Потрачено в этом месяце'
    
    def status(self, obj):
        month_start = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        spending = Transactions.objects.filter(
            bal=obj.bal,
            category=obj.category,
            dir=False,
            created_at__gte=month_start
        ).aggregate(total=models.Sum('amount'))['total'] or 0
        
        percentage = (spending / obj.limit * 100) if obj.limit > 0 else 0
        
        if percentage >= 100:
            color = 'red'
            text = f"Превышен ({percentage:.0f}%)"
        elif percentage >= 80:
            color = 'orange'
            text = f"Почти превышен ({percentage:.0f}%)"
        else:
            color = 'green'
            text = f"В норме ({percentage:.0f}%)"
        
        return format_html('<span style="color: {};">{}</span>', color, text)
    status.short_description = 'Статус'
    
    fieldsets = (
        ('Основные настройки', {
            'fields': ('bal', 'category', 'limit')
        }),
        ('Статистика', {
            'fields': (),
            'description': 'Статистика рассчитывается автоматически'
        }),
    )

@admin.register(UserTransactionView)
class UserTransactionViewAdmin(admin.ModelAdmin):
    list_display = ('transaction_id', 'amount', 'category_name', 'amount_direction', 'created_at')
    list_display_links = ('transaction_id',)
    list_filter = ('category_name', 'amount_direction', 'created_at')
    search_fields = ('category_name', 'amount_direction')
    readonly_fields = ('transaction_id', 'amount', 'category_name', 'amount_direction', 'created_at')
    ordering = ('-created_at',)
    date_hierarchy = 'created_at'
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
    
    def has_delete_permission(self, request, obj=None):
        return False
    
    class Meta:
        verbose_name = 'Представление транзакций'
        verbose_name_plural = 'Представления транзакций'

@admin.register(News)
class NewsAdmin(admin.ModelAdmin):
    # Поля, отображаемые в списке новостей
    list_display = [
        'title', 
        'description',
        'created_at',
        'updated_at',
        'is_published',
    ]
    
    # Поля для фильтрации в правой панели
    list_filter = [
        'is_published',
        'created_at',
        'updated_at'
    ]
    
    # Поля для поиска
    search_fields = [
        'title',
        'description'
    ]
    
    # Поля для редактирования прямо в списке
    list_editable = ['is_published']