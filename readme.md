Инструкция для Mac/Linux:

1. Клонируйте репозиторий
git clone https://github.com/shaurmyau/project_django.git

2. Создайте и активируйте виртуальное окружение
python -m venv venv
source venv/bin/activate

3. Установите зависимости
pip install -r requirements.txt

4.Создайте суперпользователя
python manage.py createsuperuser

5. Примените миграции
python manage.py makemigrations
python manage.py migrate

6. Создайте в БД пользователей django_admin и django_user
django_admin - все привелегии на таблицы в схеме
django_user - select и insert на таблицы в схеме, дополнительный delete на таблицу сессий и update и delete на таблицу бюджетов

7. Запустите сервер
python manage.py runserver


# Finance Tracker - Система управления финансами

Finance Tracker - это веб-приложение для управления личными финансами, разработанное на Django. Система позволяет пользователям отслеживать свои банковские карты, балансы, транзакции и бюджеты в реальном времени. Приложение включает автоматическое обновление балансов через триггеры базы данных, историю изменений всех операций и визуализацию статистики расходов.

## Features

- **Управление банковскими картами**: Создание виртуальных карт с автоматической генерацией номеров и CVV-кодов
- **Балансы и транзакции**: Отслеживание остатков на счетах и всех финансовых операций
- **Автоматические триггеры**: Реализация бизнес-логики на уровне БД для гарантии целостности данных
- **Система бюджетирования**: Установка лимитов расходов по категориям с отслеживанием прогресса
- **История изменений**: Ведение полной истории всех изменений через django-simple-history
- **Статистика и аналитика**: Просмотр детальной статистики по транзакциям через материализованные представления
- **Новостная лента**: Публикация и управление финансовыми новостями
- **Безопасность**: Аутентификация пользователей и проверка прав доступа ко всем операциям
- **Адаптивный интерфейс**: Удобный веб-интерфейс для управления финансами

## Tech Stack

- **Backend**: Python 3.11+, Django 4.2+
- **Database**: PostgreSQL 14+ (с поддержкой триггеров и представлений)
- **Frontend**: HTML5, CSS3, JavaScript, Bootstrap 5
- **Основные библиотеки**:
  - django-simple-history - история изменений моделей
  - django-pgtrigger - создание триггеров PostgreSQL
  - Pillow - работа с изображениями
- **Аутентификация**: Django Authentication System
- **Разработка**: Git, virtualenv, pip

## Installation

### 1. Клонирование репозитория
```bash
git clone <ваш-репозиторий>
cd finance-tracker
```

### 2. Создание виртуального окружения
```bash
python -m venv venv

# Для Windows:
venv\Scripts\activate

# Для Linux/Mac:
source venv/bin/activate
```

### 3. Установка зависимостей
```bash
pip install -r requirements.txt
```

### 4. Настройка базы данных PostgreSQL

Создайте базу данных в PostgreSQL:
```sql
CREATE DATABASE finance_tracker;
CREATE USER finance_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE finance_tracker TO finance_user;
```

Обновите настройки подключения в `settings.py`:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'finance_tracker',
        'USER': 'finance_user',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

### 5. Применение миграций
```bash
python manage.py makemigrations
python manage.py migrate
```

### 6. Создание суперпользователя
```bash
python manage.py createsuperuser
```
Следуйте инструкциям для создания администратора системы.

### 7. Создание материализованного представления

Выполните SQL-запрос в базе данных:
```sql
CREATE MATERIALIZED VIEW vw_user_transactions AS
SELECT 
    t.id as transaction_id,
    c.number as card_number,
    t.amount as amount,
    t.dir as amount_direction,
    t.created_at as created_at,
    cat.name as category_name
FROM main_transactions t
JOIN main_balance b ON t.bal_id = b.id
JOIN main_card c ON c.bal_id = b.id
JOIN main_category cat ON t.category_id = cat.id
ORDER BY t.created_at DESC;
```

### 8. Запуск сервера разработки
```bash
python manage.py runserver
```

Приложение будет доступно по адресу: http://localhost:8000
