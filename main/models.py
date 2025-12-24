from django.db import models
from django.contrib.auth.models import User
from django.db import connection, connections, transaction
from datetime import datetime, timedelta
from django.utils import timezone
from random import randint
import pgtrigger
from datetime import timedelta
from simple_history.models import HistoricalRecords

class Category(models.Model):
    
    history = HistoricalRecords()
    
    name = models.CharField(max_length=100, verbose_name='Название категории')
    
    class Meta:
        verbose_name = 'Категория'
        verbose_name_plural = 'Категории'
    
    def __str__(self):
        return self.name

class Balance(models.Model):
    
    history = HistoricalRecords()
    
    owner = models.ForeignKey(
        User,
        on_delete = models.CASCADE,
        verbose_name = 'Владелец карты',
    )
    
    bal = models.PositiveIntegerField(
        verbose_name='Денег на счету',
    )
    
    def __str__(self):
        res = str(f"{self.owner.username} - счёт номер {self.pk}")
        card = Card.objects.filter(bal=self).first()
        if card:
            res += f" - карта номер {card.number}"
        return res
    
    class Meta:
        verbose_name = 'Баланс'
        verbose_name_plural = 'Балансы'
    
def generate_number():
    while True:
        a = ' '.join([str(randint(1000000000000000, 9999999999999999))[i:i+4] for i in range(0, 16, 4)])
        if not Card.objects.filter(number=a).exists():
            return a

def generate_CVV():
    return str(randint(100, 999))
        
class Card(models.Model):
    
    history = HistoricalRecords()
    
    bal = models.ForeignKey(
        Balance,
        on_delete = models.CASCADE,
        verbose_name = 'Счёт',
    )
    
    number = models.CharField(
        verbose_name='Номер карты',
        default = generate_number,
        unique=True,
    )

    CVV = models.PositiveIntegerField(
        verbose_name='Код CVV',
        default = generate_CVV,
    )
    
    date = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Дата действия'
    )
    
    @property
    def expiration_date(self):
        return self.date + timedelta(days=365*4)
    
    class Meta:
            verbose_name = 'Карта'
            verbose_name_plural = 'Карты'
    
class Transactions(models.Model):
    
    history = HistoricalRecords()
    
    bal = models.ForeignKey(
        Balance,
        on_delete = models.CASCADE,
        verbose_name = 'Счёт',
    )
    
    amount = models.PositiveIntegerField(
        verbose_name='Кол-во денег',
    )
    
    category = models.ForeignKey(
        Category,
        on_delete = models.CASCADE,
        verbose_name = 'Категория',
    )
    
    dir = models.BooleanField(
        verbose_name = 'Направление',
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True, 
        verbose_name='Дата транзакции'
    )
    
    class Meta:
        verbose_name = 'Транзакция'
        verbose_name_plural = 'Транзакции'
        triggers = [
            # Триггер для INSERT - добавление транзакции
            pgtrigger.Trigger(
                name='update_balance_on_insert',
                level=pgtrigger.Row,
                when=pgtrigger.After,
                operation=pgtrigger.Insert,
                func="""
                    BEGIN
                        IF NEW.dir THEN
                            -- Если dir = True (доход), прибавляем деньги
                            UPDATE main_balance 
                            SET bal = bal + NEW.amount 
                            WHERE id = NEW.bal_id;
                        ELSE
                            -- Если dir = False (расход), проверяем баланс и отнимаем деньги
                            DECLARE
                                current_balance INTEGER;
                            BEGIN
                                SELECT bal INTO current_balance 
                                FROM main_balance 
                                WHERE id = NEW.bal_id
                                FOR UPDATE;
                                
                                IF current_balance >= NEW.amount THEN
                                    UPDATE main_balance 
                                    SET bal = bal - NEW.amount 
                                    WHERE id = NEW.bal_id;
                                ELSE
                                    RAISE EXCEPTION 'Недостаточно средств на счету. Доступно: %, требуется: %', 
                                    current_balance, NEW.amount;
                                END IF;
                            END;
                        END IF;
                        RETURN NEW;
                    END;
                """,
            ),
            
            # Триггер для UPDATE - обновление транзакции
            pgtrigger.Trigger(
                name='update_balance_on_update',
                level=pgtrigger.Row,
                when=pgtrigger.After,
                operation=pgtrigger.Update,
                func="""
                    BEGIN
                        -- Сначала возвращаем старые деньги
                        IF OLD.dir THEN
                            -- Старая транзакция была доходом - отнимаем
                            UPDATE main_balance 
                            SET bal = bal - OLD.amount 
                            WHERE id = OLD.bal_id;
                        ELSE
                            -- Старая транзакция была расходом - возвращаем
                            UPDATE main_balance 
                            SET bal = bal + OLD.amount 
                            WHERE id = OLD.bal_id;
                        END IF;
                        
                        -- Затем применяем новые значения
                        IF NEW.dir THEN
                            -- Новая транзакция - доход, прибавляем
                            UPDATE main_balance 
                            SET bal = bal + NEW.amount 
                            WHERE id = NEW.bal_id;
                        ELSE
                            -- Новая транзакция - расход, проверяем баланс
                            DECLARE
                                current_balance INTEGER;
                            BEGIN
                                SELECT bal INTO current_balance 
                                FROM main_balance 
                                WHERE id = NEW.bal_id
                                FOR UPDATE;
                                
                                IF current_balance >= NEW.amount THEN
                                    UPDATE main_balance 
                                    SET bal = bal - NEW.amount 
                                    WHERE id = NEW.bal_id;
                                ELSE
                                    -- Возвращаем старые деньги обратно (откатываем первую операцию)
                                    IF OLD.dir THEN
                                        UPDATE main_balance 
                                        SET bal = bal + OLD.amount 
                                        WHERE id = OLD.bal_id;
                                    ELSE
                                        UPDATE main_balance 
                                        SET bal = bal - OLD.amount 
                                        WHERE id = OLD.bal_id;
                                    END IF;
                                    
                                    RAISE EXCEPTION 'Недостаточно средств на счету после обновления. Требуется: %', 
                                    NEW.amount;
                                END IF;
                            END;
                        END IF;
                        RETURN NEW;
                    END;
                """,
                condition=pgtrigger.Q(old__bal_id=pgtrigger.F('new__bal_id'))
            ),
            
            # Триггер для DELETE - удаление транзакции
            pgtrigger.Trigger(
                name='update_balance_on_delete',
                level=pgtrigger.Row,
                when=pgtrigger.Before,
                operation=pgtrigger.Delete,
                func="""
                    BEGIN
                        -- Возвращаем деньги при удалении транзакции
                        IF OLD.dir THEN
                            -- Удаляем доход - отнимаем деньги
                            UPDATE main_balance 
                            SET bal = bal - OLD.amount 
                            WHERE id = OLD.bal_id;
                        ELSE
                            -- Удаляем расход - возвращаем деньги
                            UPDATE main_balance 
                            SET bal = bal + OLD.amount 
                            WHERE id = OLD.bal_id;
                        END IF;
                        RETURN OLD;
                    END;
                """,
            ),
        ]
    
class Budget(models.Model):
    
    history = HistoricalRecords()
    
    bal = models.ForeignKey(
        Balance,
        on_delete = models.CASCADE,
        verbose_name = 'Счёт',
    )
    
    category = models.ForeignKey(
        Category,
        on_delete = models.CASCADE,
        verbose_name = 'Категория',
    )
    
    limit = models.PositiveIntegerField(
        verbose_name='Лимит трат за месяц',
    )
    
    class Meta:
        verbose_name = 'Ограничение бюжета'
        verbose_name_plural = 'Ограничения бюжета'
    
class UserTransactionView(models.Model):
    """Модель для представления vw_user_transactions"""
    transaction_id = models.IntegerField(primary_key=True)
    card_number = models.CharField()
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    amount_direction = models.BooleanField()
    created_at = models.DateTimeField()
    category_name = models.CharField(max_length=100, null=True, blank=True)
    
    class Meta:
        managed = False
        db_table = 'vw_user_transactions'
        ordering = ['-created_at']
        verbose_name = 'Статистика транзакций'
        verbose_name_plural = 'Статистика транзакций'

# Добавьте в models.py после существующих моделей
class News(models.Model):
    
    history = HistoricalRecords()
    
    title = models.CharField(
        max_length=200,
        verbose_name='Заголовок новости'
    )
    
    description = models.TextField(
        verbose_name='Описание новости',
        help_text='Полный текст новости'
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Дата создания'
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Дата обновления'
    )
    
    is_published = models.BooleanField(
        default=True,
        verbose_name='Опубликовано'
    )
    
    image = models.ImageField(
        upload_to='news_images/',
        blank=True,
        null=True,
        verbose_name='Изображение'
    )
    
    class Meta:
        verbose_name = 'Новость'
        verbose_name_plural = 'Новости'
        ordering = ['-created_at']
    
    def __str__(self):
        return self.title
    
    def short_description(self):
        if len(self.description) > 150:
            return self.description[:150] + '...'
        return self.description