from django.urls import path
from . import views
from .views import CardDetailView

urlpatterns = [
    path('', views.home, name='home'),
    path('account/', views.CardListView.as_view(), name='account'),
    path('account/budget/', views.budget, name='budget'),
    path('account/stats/', views.TransactionListView.as_view(), name='transactions'),
    path('account/card-<int:pk>/', CardDetailView.as_view(), name = 'card_detail'),
    path('account/balance-<int:pk>/', views.BalanceDetailView.as_view(), name = 'balance_detail'),
    path('register/', views.register_view, name='register'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('budget/', views.BudgetListView.as_view(), name='budget-list'),
    path('budget/create/', views.BudgetCreateView.as_view(), name='budget-create'),
    path('budget/<int:pk>/update/', views.BudgetUpdateView.as_view(), name='budget-update'),
    path('budget/<int:pk>/delete/', views.BudgetDeleteView.as_view(), name='budget-delete'),
    path('create-transaction/', views.CreateTransactionView.as_view(), name='create_transaction'),
    path('news/', views.NewsListView.as_view(), name='news-list'),
    path('news/<int:pk>/', views.NewsDetailView.as_view(), name='news-detail'),
]