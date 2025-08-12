# Create your models here.
from django.contrib.gis.db import models

class Login(models.Model):
    nom = models.TextField()
    prenom = models.TextField()
    mail = models.TextField(unique=True)
    mdp = models.TextField()
    role = models.TextField()


    class Meta:
        db_table = 'login'  # Nom exact de ta table dans PostgreSQL
        managed = False     # Empêche Django de gérer la création/modification de cette table

    def __str__(self):
        return self.mail


class Piste(models.Model):
    geom = models.LineStringField(srid=4326)
    communes_rurales_id = models.IntegerField()
    code_piste = models.IntegerField(null=True, blank=True)
    user_login = models.TextField(null=True, blank=True)
    heure_debut = models.DateTimeField(null=True, blank=True)
    heure_fin = models.DateTimeField(null=True, blank=True)
    nom_origine_piste = models.TextField(null=True, blank=True)
    x_origine = models.FloatField(null=True, blank=True)
    y_origine = models.FloatField(null=True, blank=True)
    nom_destination_piste = models.TextField(null=True, blank=True)
    x_destination = models.FloatField(null=True, blank=True)
    y_destination = models.FloatField(null=True, blank=True)
    existence_intersection = models.IntegerField(null=True, blank=True)
    x_intersection = models.FloatField(null=True, blank=True)
    y_intersection = models.FloatField(null=True, blank=True)
    type_occupation = models.TextField(null=True, blank=True)
    debut_occupation = models.DateTimeField(null=True, blank=True)
    fin_occupation = models.DateTimeField(null=True, blank=True)
    largeur_emprise = models.FloatField(null=True, blank=True)
    frequence_trafic = models.FloatField(null=True, blank=True)
    type_trafic = models.TextField(null=True, blank=True)
    travaux_realises = models.TextField(null=True, blank=True)
    date_travaux = models.TextField(null=True, blank=True)
    entreprise = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'pistes'
        managed = False  # Si la table est déjà créée dans la base

    def __str__(self):
        return f"Piste {self.id} - Code {self.code_piste}"