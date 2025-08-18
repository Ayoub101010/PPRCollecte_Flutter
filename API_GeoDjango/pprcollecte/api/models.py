from django.contrib.gis.db import models

class Login(models.Model):
    nom = models.TextField()
    prenom = models.TextField()
    mail = models.TextField(unique=True)
    mdp = models.TextField()
    role = models.TextField()

    class Meta:
        db_table = 'login'
        managed = False

    def __str__(self):
        return f"{self.nom} {self.prenom} ({self.mail})"


from django.contrib.gis.db import models


class Region(models.Model):
    nom = models.TextField()
    geom = models.GeometryField(null=True, blank=True)
    created_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'regions'
        managed = False

    def __str__(self):
        return self.nom


class Prefecture(models.Model):
    regions_id = models.ForeignKey(
        Region,
        db_column='regions_id',
        on_delete=models.CASCADE
    )    
    nom = models.TextField()
    geom = models.GeometryField(null=True, blank=True)
    created_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'prefectures'
        managed = False

    def __str__(self):
        return self.nom


class CommuneRurale(models.Model):
    prefectures_id = models.ForeignKey(Prefecture, on_delete=models.SET_NULL, null=True, blank=True, db_column='prefectures_id')
    nom = models.TextField()
    geom = models.GeometryField(null=True, blank=True)
    created_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'communes_rurales'
        managed = False

    def __str__(self):
        return self.nom
    
class Piste(models.Model):
    communes_rurales_id = models.ForeignKey(
        CommuneRurale, 
        on_delete=models.SET_NULL,  # ou CASCADE si tu veux supprimer les pistes avec la commune
        null=True, 
        blank=True, 
        db_column='communes_rurales_id'
    )
    code_piste = models.IntegerField(unique=True, null=True, blank=True)
    geom = models.LineStringField(srid=4326, null=True, blank=True)
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
    login_id = models.ForeignKey(
        'Login',  # suppose que tu as un modèle Login
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='login_id'
    )

    class Meta:
        db_table = 'pistes'
        managed = False  # mettre True si tu veux que Django gère la table

    def __str__(self):
        return f"Piste {self.code_piste} - {self.nom_origine_piste} → {self.nom_destination_piste}"


class ServicesSantes(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_sante = models.FloatField(null=True, blank=True)
    y_sante = models.FloatField(null=True, blank=True)
    nom = models.CharField(max_length=254, null=True, blank=True)
    type = models.CharField(max_length=254, null=True, blank=True)
    date_creat = models.DateField(null=True, blank=True)
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'services_santes'
        managed = False

    def __str__(self):
        return f"{self.nom} ({self.fid})"


class AutresInfrastructures(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_autre_in = models.FloatField(null=True, blank=True)
    y_autre_in = models.FloatField(null=True, blank=True)
    type = models.CharField(max_length=254, null=True, blank=True)
    date_creat = models.DateField(null=True, blank=True)
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'autres_infrastructures'
        managed = False

    def __str__(self):
        return f"Autre infrastructure ({self.fid})"


class Bacs(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_debut_tr = models.FloatField(null=True, blank=True)
    y_debut_tr = models.FloatField(null=True, blank=True)
    x_fin_trav = models.FloatField(null=True, blank=True)
    y_fin_trav = models.FloatField(null=True, blank=True)
    type_bac = models.CharField(max_length=254, null=True, blank=True)
    nom_cours = models.CharField(max_length=254, null=True, blank=True, db_column='nom_cours_')
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    endroit = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'bacs'
        managed = False

    def __str__(self):
        return f"Bac {self.fid}"


class BatimentsAdministratifs(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_batiment = models.FloatField(null=True, blank=True)
    y_batiment = models.FloatField(null=True, blank=True)
    nom = models.CharField(max_length=254, null=True, blank=True)
    type = models.CharField(max_length=254, null=True, blank=True)
    date_creat = models.DateField(null=True, blank=True)
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'batiments_administratifs'
        managed = False

    def __str__(self):
        return f"{self.nom} ({self.fid})"


class Buses(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_buse = models.FloatField(null=True, blank=True)
    y_buse = models.FloatField(null=True, blank=True)
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'buses'
        managed = False

    def __str__(self):
        return f"Buse {self.fid}"


class Dalots(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_dalot = models.FloatField(null=True, blank=True)
    y_dalot = models.FloatField(null=True, blank=True)
    situation = models.CharField(max_length=254, null=True, blank=True, db_column='situation_')
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'dalots'
        managed = False

    def __str__(self):
        return f"Dalot {self.fid}"


class Ecoles(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_ecole = models.FloatField(null=True, blank=True)
    y_ecole = models.FloatField(null=True, blank=True)
    nom = models.CharField(max_length=254, null=True, blank=True)
    type = models.CharField(max_length=254, null=True, blank=True)
    date_creat = models.DateField(null=True, blank=True)
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'ecoles'
        managed = False

    def __str__(self):
        return f"{self.nom} ({self.fid})"


class InfrastructuresHydrauliques(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_infrastr = models.FloatField(null=True, blank=True)
    y_infrastr = models.FloatField(null=True, blank=True)
    nom = models.CharField(max_length=254, null=True, blank=True)
    type = models.CharField(max_length=254, null=True, blank=True)
    date_creat = models.DateField(null=True, blank=True)
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'infrastructures_hydrauliques'
        managed = False

    def __str__(self):
        return f"{self.nom} ({self.fid})"


class Localites(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_localite = models.FloatField(null=True, blank=True)
    y_localite = models.FloatField(null=True, blank=True)
    nom = models.CharField(max_length=254, null=True, blank=True)
    type = models.CharField(max_length=254, null=True, blank=True)
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'localites'
        managed = False

    def __str__(self):
        return f"{self.nom} ({self.fid})"


class Marches(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_marche = models.FloatField(null=True, blank=True)
    y_marche = models.FloatField(null=True, blank=True)
    nom = models.CharField(max_length=254, null=True, blank=True)
    type = models.CharField(max_length=254, null=True, blank=True)
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'marches'
        managed = False

    def __str__(self):
        return f"{self.nom} ({self.fid})"


class PassagesSubmersibles(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_debut_pa = models.FloatField(null=True, blank=True)
    y_debut_pa = models.FloatField(null=True, blank=True)
    x_fin_pass = models.FloatField(null=True, blank=True)
    y_fin_pass = models.FloatField(null=True, blank=True)
    type_mater = models.CharField(max_length=254, null=True, blank=True)
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    endroit = models.CharField(max_length=32, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'passages_submersibles'
        managed = False

    def __str__(self):
        return f"Passage {self.fid}"


class Ponts(models.Model):
    fid = models.BigIntegerField(primary_key=True)
    geom = models.PointField(srid=4326)
    id = models.FloatField(null=True, blank=True)
    x_pont = models.FloatField(null=True, blank=True)
    y_pont = models.FloatField(null=True, blank=True)
    situation = models.CharField(max_length=254, null=True, blank=True, db_column='situation_')
    type_pont = models.CharField(max_length=254, null=True, blank=True)
    nom_cours = models.CharField(max_length=254, null=True, blank=True, db_column='nom_cours_')
    created_at = models.CharField(max_length=24, null=True, blank=True)
    updated_at = models.CharField(max_length=24, null=True, blank=True)
    code_gps = models.CharField(max_length=254, null=True, blank=True)
    code_piste = models.ForeignKey(
    Piste,
    to_field='code_piste',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='code_piste'
)

    login_id = models.ForeignKey(
    Login,
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    db_column='login_id'
)



    class Meta:
        db_table = 'ponts'
        managed = False

    def __str__(self):
        return f"Pont {self.fid} - {self.nom_cours or ''}"

