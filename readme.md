Инструкция для Mac/Linux:

1. Клонируйте репозиторий
git clone https://github.com/ваш-username/project_study_hub.git
cd project_study_hub

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