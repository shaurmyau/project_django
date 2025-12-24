from django import forms
from .models import Transactions

class TransactionForm(forms.ModelForm):
    class Meta:
        model = Transactions
        fields = ['bal', 'amount', 'category', 'dir']
        widgets = {
            'bal': forms.Select(attrs={'class': 'form-control'}),
            'amount': forms.NumberInput(attrs={
                'class': 'form-control',
                'min': '1',
                'step': '1'
            }),
            'category': forms.Select(attrs={'class': 'form-control'}),
            'dir': forms.Select(choices=[(True, 'Доход'), (False, 'Расход')], 
                                attrs={'class': 'form-control'}),
        }
        