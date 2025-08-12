from django.urls import path
from api.views import LoginAPIView  # import absolu recommandé
from .views import PisteListCreateAPIView

urlpatterns = [
    path('api/login/', LoginAPIView.as_view(), name='api-login'),
     path('api/pistes/', PisteListCreateAPIView.as_view(), name='api-pistes'),
]
