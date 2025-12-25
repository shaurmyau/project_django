# Personal Finance Manager

Веб-приложение для управления личными финансами, разработанное на Django. Позволяет пользователям отслеживать банковские карты, транзакции, устанавливать бюджетные ограничения и анализировать финансовую статистику. Система включает в себя расширенные функции безопасности, историю изменений и триггеры на уровне базы данных.

## Features

- **Управление банковскими картами**: Автоматическая генерация номеров карт, CVV кодов и отслеживание сроков действия
- **Транзакции**: Учет доходов и расходов с автоматическим обновлением баланса через триггеры PostgreSQL
- **Контроль бюджета**: Установка месячных лимитов по категориям расходов с визуализацией прогресса
- **Статистика**: Просмотр детальной статистики транзакций с фильтрацией по датам, категориям и типам операций
- **История изменений**: Отслеживание всех изменений в моделях через django-simple-history
- **Безопасность**: Middleware для автоматического переключения пользователей базы данных в зависимости от ролей
- **Новостная лента**: Публикация и просмотр финансовых новостей
- **Панель администратора**: Расширенный административный интерфейс Django

## Tech Stack

- **Backend**: Python 3.8+, Django 5.2
- **Database**: PostgreSQL 13+ с триггерами и представлениями
- **Database ORM**: Django ORM
- **Security**: Django authentication, role-based database access
- **History Tracking**: django-simple-history
- **Database Triggers**: django-pgtrigger
- **Development Tools**: django-extensions
- **Frontend**: HTML5, CSS3, JavaScript, Bootstrap 5
- **Templates**: Django Template Language

## Installation

### Предварительные требования

1. **Python 3.8 или выше**
   ```bash
   python --version
   ```

2. **PostgreSQL 13 или выше**
   ```bash
   psql --version
   ```

3. **Git**
   ```bash
   git --version
   ```

### Шаг 1: Клонирование репозитория

```bash
git clone https://github.com/shaurmyau/project_django.git
cd myportfolio
```

### Шаг 2: Создание виртуального окружения

```bash
# Для Linux/Mac
python -m venv venv
source venv/bin/activate

# Для Windows
python -m venv venv
venv\Scripts\activate
```

### Шаг 3: Установка зависимостей

```bash
pip install -r requirements.txt
```

Если файла requirements.txt нет, установите зависимости вручную:

```bash
pip install django==5.2
pip install psycopg2-binary
pip install django-pgtrigger
pip install django-simple-history
pip install django-extensions
```

### Шаг 4: Настройка базы данных PostgreSQL

1. Подключитесь к PostgreSQL:
```bash
sudo -u postgres psql
```

2. Создайте базу данных и пользователей:
```sql
CREATE DATABASE project_2;
CREATE USER django_admin WITH PASSWORD '2585';
CREATE USER django_user WITH PASSWORD '1234';

-- Дайте права администратору
GRANT ALL PRIVILEGES ON DATABASE project_2 TO django_admin;

-- Дайте права обычному пользователю
GRANT CONNECT ON DATABASE project_2 TO django_user;
```

### Шаг 5: Настройка проекта

1. Проверьте настройки в `settings.py`:
   - Убедитесь, что `DEBUG = True` для разработки
   - Проверьте настройки базы данных
   - Убедитесь, что `ALLOWED_HOSTS` содержит нужные домены

2. Примените миграции:
```bash
python manage.py makemigrations
python manage.py migrate
```

### Шаг 6: Создание суперпользователя

```bash
python manage.py createsuperuser
```
Следуйте инструкциям для создания административной учетной записи.

### Шаг 7: Запуск сервера разработки

```bash
python manage.py runserver
```

Приложение будет доступно по адресу: http://127.0.0.1:8000/

## Дополнительная информация
### Важные особенности

1. **Триггеры базы данных**: Автоматическое обновление баланса при операциях с транзакциями
2. **История изменений**: Все изменения в моделях сохраняются для аудита
3. **Ролевая модель базы данных**: Разделение прав доступа через разных пользователей PostgreSQL
4. **Автогенерация данных**: Карты и CVV коды генерируются автоматически