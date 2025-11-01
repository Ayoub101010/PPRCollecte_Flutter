from django.shortcuts import render

# Create your views here.
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework import generics
from django.contrib.gis.db.models.functions import Transform
from .models import Login
from .serializers import LoginSerializer, PisteReadSerializer, PisteWriteSerializer
from .models import Piste
from .models import (
    ServicesSantes, AutresInfrastructures, Bacs, BatimentsAdministratifs,
    Buses, Dalots, Ecoles, InfrastructuresHydrauliques, Localites,
    Marches, PassagesSubmersibles, Ponts, CommuneRurale, Prefecture, Region, ChausseesTest
)
from .serializers import (
    ServicesSantesSerializer, AutresInfrastructuresSerializer, BacsSerializer,
    BatimentsAdministratifsSerializer, BusesSerializer, DalotsSerializer,
    EcolesSerializer, InfrastructuresHydrauliquesSerializer, LocalitesSerializer,
    MarchesSerializer, PassagesSubmersiblesSerializer, PontsSerializer, CommuneRuraleSerializer,
      PrefectureSerializer, RegionSerializer,UserCreateSerializer, UserUpdateSerializer, ChausseesTestSerializer
)

class RegionsListCreateAPIView(generics.ListCreateAPIView):
    queryset = Region.objects.all()
    serializer_class = RegionSerializer

class PrefecturesListCreateAPIView(generics.ListCreateAPIView):
    queryset = Prefecture.objects.all()
    serializer_class = PrefectureSerializer

class CommunesRuralesListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = CommuneRuraleSerializer
    
    def get_queryset(self):
        queryset = CommuneRurale.objects.select_related(
            'prefectures_id',
            'prefectures_id__regions_id'
        )
        
        # Ajouter le filtre de recherche
        search = self.request.GET.get('q', '')
        if search:
            queryset = queryset.filter(nom__icontains=search)
        
        return queryset.order_by('nom')

# Modifiez toutes vos vues pour qu'elles ressemblent à ceci :
class ChausseesTestListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = ChausseesTestSerializer

    def get_queryset(self):
        qs = ChausseesTest.objects.all()

        # Filtres optionnels (cohérents avec tes autres vues)
        commune_id = self.request.query_params.get('communes_rurales_id')
        if commune_id:
            qs = qs.filter(communes_rurales_id=commune_id)

        code_piste = self.request.query_params.get('code_piste')
        if code_piste:
            qs = qs.filter(code_piste_id=code_piste)

        return qs
class ServicesSantesListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = ServicesSantesSerializer
    
    def get_queryset(self):
        queryset = ServicesSantes.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class AutresInfrastructuresListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = AutresInfrastructuresSerializer
    
    def get_queryset(self):
        queryset = AutresInfrastructures.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class BacsListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = BacsSerializer
    
    def get_queryset(self):
        queryset = Bacs.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class BatimentsAdministratifsListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = BatimentsAdministratifsSerializer
    
    def get_queryset(self):
        queryset = BatimentsAdministratifs.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class BusesListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = BusesSerializer
    
    def get_queryset(self):
        queryset = Buses.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class DalotsListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = DalotsSerializer
    
    def get_queryset(self):
        queryset = Dalots.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class EcolesListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = EcolesSerializer
    
    def get_queryset(self):
        queryset = Ecoles.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class InfrastructuresHydrauliquesListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = InfrastructuresHydrauliquesSerializer
    
    def get_queryset(self):
        queryset = InfrastructuresHydrauliques.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class LocalitesListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = LocalitesSerializer
    
    def get_queryset(self):
        queryset = Localites.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class MarchesListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = MarchesSerializer
    
    def get_queryset(self):
        queryset = Marches.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class PassagesSubmersiblesListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = PassagesSubmersiblesSerializer
    
    def get_queryset(self):
        queryset = PassagesSubmersibles.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset

class PontsListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = PontsSerializer
    
    def get_queryset(self):
        queryset = Ponts.objects.all()
        commune_id = self.request.query_params.get('commune_id')
        if commune_id:
            queryset = queryset.filter(commune_id=commune_id)
        return queryset




class LoginAPIView(APIView):
     # GET pour récupérer tous les utilisateurs
    def get(self, request):
        users = Login.objects.all()
        serializer = LoginSerializer(users, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    
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

    def get_queryset(self):
        qs = Piste.objects.all()

        commune_id = self.request.query_params.get('communes_rurales_id')
        if commune_id:
            qs = qs.filter(communes_rurales_id=commune_id)

        # IMPORTANT : on annote bien un alias 'geom_4326'
        return qs.annotate(geom_4326=Transform('geom', 4326))

    def get_serializer_class(self):
        # GET => serializer lecture (expose geom_4326)
        if self.request.method == 'GET':
            return PisteReadSerializer
        # POST/PUT => serializer écriture (reçoit/stocker en 32628)
        return PisteWriteSerializer

    def perform_create(self, serializer):
        serializer.save()

class UserManagementAPIView(APIView):
    """API dédiée à la gestion des utilisateurs par le super_admin"""
    
    def post(self, request):
        """Créer un nouvel utilisateur avec commune"""
        print(f"🔍 Données reçues pour création utilisateur:", request.data)  # Ajout debug
        
        serializer = UserCreateSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            response_serializer = LoginSerializer(user)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        else:
            print(f"❌ Erreurs de validation:", serializer.errors)  # Ajout debug
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def get(self, request, user_id=None):
        """Lister tous les utilisateurs ou récupérer un utilisateur spécifique"""
        if user_id:
            try:
                user = Login.objects.select_related(
                    'communes_rurales_id',
                    'communes_rurales_id__prefectures_id',
                    'communes_rurales_id__prefectures_id__regions_id'
                ).get(id=user_id)
                serializer = LoginSerializer(user)
                return Response(serializer.data, status=status.HTTP_200_OK)
            except Login.DoesNotExist:
                return Response({"error": "Utilisateur non trouvé"}, status=status.HTTP_404_NOT_FOUND)
        else:
            queryset = Login.objects.select_related(
                'communes_rurales_id',
                'communes_rurales_id__prefectures_id',
                'communes_rurales_id__prefectures_id__regions_id'
            )
            
            role = request.GET.get('role')
            region_id = request.GET.get('region_id')
            prefecture_id = request.GET.get('prefecture_id')
            commune_id = request.GET.get('commune_id')
            
            if role:
                queryset = queryset.filter(role=role)
            if region_id:
                queryset = queryset.filter(communes_rurales_id__prefectures_id__regions_id=region_id)
            if prefecture_id:
                queryset = queryset.filter(communes_rurales_id__prefectures_id=prefecture_id)
            if commune_id:
                queryset = queryset.filter(communes_rurales_id=commune_id)
            
            serializer = LoginSerializer(queryset, many=True)
            return Response({
                'users': serializer.data,
                'total': queryset.count()
            }, status=status.HTTP_200_OK)
    
    def put(self, request, user_id=None):
        """Modifier un utilisateur existant"""
        print(f"🔍 PUT /api/users/{user_id}/ - Données reçues:", request.data)
        
        if not user_id:
            return Response({"error": "ID utilisateur requis"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = Login.objects.get(id=user_id)
            print(f"✅ Utilisateur trouvé: {user.nom} {user.prenom}")
        except Login.DoesNotExist:
            print(f"❌ Utilisateur {user_id} non trouvé")
            return Response({"error": "Utilisateur non trouvé"}, status=status.HTTP_404_NOT_FOUND)
        
        serializer = UserUpdateSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            print("✅ Serializer valide")
            serializer.save()
            user.refresh_from_db()
            response_serializer = LoginSerializer(user)
            return Response(response_serializer.data, status=status.HTTP_200_OK)
        else:
            print(f"❌ Erreurs de validation: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, user_id=None):
        """Supprimer un utilisateur"""
        if not user_id:
            return Response({"error": "ID utilisateur requis"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = Login.objects.get(id=user_id)
            user_info = f"{user.nom} {user.prenom}"
            user.delete()
            return Response({
                "message": f"Utilisateur {user_info} supprimé avec succès"
            }, status=status.HTTP_200_OK)
        except Login.DoesNotExist:
            return Response({"error": "Utilisateur non trouvé"}, status=status.HTTP_404_NOT_FOUND)