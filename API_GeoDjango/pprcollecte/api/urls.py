from django.urls import path
from api.views import LoginAPIView  # import absolu recommandé

urlpatterns = [
    path('api/login/', LoginAPIView.as_view(), name='api-login'),
]
