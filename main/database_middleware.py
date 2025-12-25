from django.db import connections
from django.contrib.auth.models import AnonymousUser

class DatabaseUserMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Проверяем есть ли user (после AuthenticationMiddleware)
        if hasattr(request, 'user') and not isinstance(request.user, AnonymousUser):
            if request.user.is_staff:
                # Админы используют django_admin
                self._switch_user('django_admin', '2585')
            else:
                # Обычные пользователи используют django_user
                self._switch_user('django_user', '1234')
        else:
            # Неавторизованные пользователи - используем django_user или вообще не меняем
            self._switch_user('django_user', '1234')
        
        response = self.get_response(request)
        return response

    def _switch_user(self, username, password):
        # Меняем учетные данные в текущем соединении
        connections['default'].settings_dict['USER'] = username
        connections['default'].settings_dict['PASSWORD'] = password
        # Закрываем старое соединение
        connections['default'].close()