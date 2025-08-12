from django.shortcuts import render

# Create your views here.
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework import generics

from .models import Login
from .serializers import LoginSerializer, PisteSerializer
from .models import Piste




class LoginAPIView(APIView):
    def post(self, request):
        mail = request.data.get('mail')
        mdp = request.data.get('mdp')

        if not mail or not mdp:
            return Response({"error": "Mail et mot de passe requis"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = Login.objects.get(mail=mail)
        except Login.DoesNotExist:
            return Response({"error": "Utilisateur non trouvé"}, status=status.HTTP_404_NOT_FOUND)

        if user.mdp != mdp:
            return Response({"error": "Mot de passe incorrect"}, status=status.HTTP_401_UNAUTHORIZED)

        serializer = LoginSerializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)


class PisteListCreateAPIView(generics.ListCreateAPIView):
    queryset = Piste.objects.all()
    serializer_class = PisteSerializer