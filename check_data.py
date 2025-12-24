# check_data.py (обновленная версия)
import os
import django
import sys

sys.path.append('/home/zahar/sirius/programs/django/project_2')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myportfolio.settings')
django.setup()

from main.models import UserTransactionView

print("=" * 50)
print("ПРОВЕРКА ДАННЫХ В vw_user_transactions (boolean тип)")
print("=" * 50)

# Проверяем количество записей
count = UserTransactionView.objects.count()
print(f"Всего записей в представлении: {count}")

if count > 0:
    # Смотрим первую запись детально
    tx = UserTransactionView.objects.first()
    print("\nДетали первой записи:")
    print(f"ID: {tx.transaction_id}")
    print(f"Карта: {tx.card_number}")
    print(f"Сумма: {tx.amount}")
    print(f"Тип (boolean): {tx.amount_direction}")
    print(f"Тип (тип Python): {type(tx.amount_direction)}")
    print(f"Категория: {tx.category_name}")
    print(f"Дата: {tx.created_at}")
    
    # Проверяем логику: что означает True/False?
    print("\nПроверка логики boolean:")
    print(f"  Если amount_direction = True, это доход?")
    print(f"  Если amount_direction = False, это расход?")
    
    # Считаем по boolean значениям
    true_count = UserTransactionView.objects.filter(amount_direction=True).count()
    false_count = UserTransactionView.objects.filter(amount_direction=False).count()
    
    print(f"\nРаспределение по boolean значениям:")
    print(f"  True: {true_count} записей")
    print(f"  False: {false_count} записей")
    
    # Проверяем знаки сумм для определения логики
    print("\nАнализ логики:")
    true_sum = sum(tx.amount for tx in UserTransactionView.objects.filter(amount_direction=True))
    false_sum = sum(tx.amount for tx in UserTransactionView.objects.filter(amount_direction=False))
    
    print(f"  Сумма при True: {true_sum}")
    print(f"  Сумма при False: {false_sum}")
    
    if true_sum > 0 and false_sum <= 0:
        print("  ВЫВОД: True = доходы, False = расходы")
    elif false_sum > 0 and true_sum <= 0:
        print("  ВЫВОД: False = доходы, True = расходы")
    else:
        print("  ВЫВОД: Не удалось определить логику автоматически")

print("=" * 50)