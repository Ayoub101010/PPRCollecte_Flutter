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

