// lib/infrastructure_config.dart
class InfrastructureConfig {
  static const Map<String, Map<String, dynamic>> config = {
    "Infrastructures Rurales": {
      "icon": "location_city",
      "color": 0xFF4CAF50,
      "entities": {
        "Localité": {
          "tableName": "localites",
          "fields": ["piste_id", "x_localite", "y_localite", "nom", "type"],
          "typeOptions": [
            "village",
            "chef-lieu de district",
            "chef-lieu de préfecture",
            "ville",
            "autre"
          ]
        },
        "École": {
          "tableName": "ecoles",
          "fields": [
            "piste_id",
            "x_ecole",
            "y_ecole",
            "nom",
            "type",
            "date_creation"
          ],
          "typeOptions": ["primaire", "secondaire", "universitaire"]
        },
        "Marché": {
          "tableName": "marches",
          "fields": ["piste_id", "x_marche", "y_marche", "nom", "type"],
          "typeOptions": ["quotidien", "hebdomadaire"]
        },
        "Service de Santé": {
          "tableName": "services_santes",
          "fields": [
            "piste_id",
            "x_sante",
            "y_sante",
            "nom",
            "type",
            "date_creation"
          ],
          "typeOptions": ["dispensaire", "centre de santé", "hôpital"]
        },
        "Bâtiment Administratif": {
          "tableName": "batiments_administratifs",
          "fields": [
            "piste_id",
            "x_batiment_administratif",
            "y_batiment_administratif",
            "nom",
            "type",
            "date_creation"
          ],
          "typeOptions": [
            "mairie",
            "poste de police",
            "bureau de poste",
            "autre"
          ]
        },
        "Infrastructure Hydraulique": {
          "tableName": "infrastructures_hydrauliques",
          "fields": [
            "piste_id",
            "x_infrastructure_hydraulique",
            "y_infrastructure_hydraulique_2",
            "nom",
            "type",
            "date_creation"
          ],
          "typeOptions": ["forage", "source améliorée", "autre"]
        },
        "Autre Infrastructure": {
          "tableName": "autres_infrastructures",
          "fields": [
            "piste_id",
            "x_autre_infrastructure",
            "y_autre_infrastructure",
            "nom",
            "type",
            "date_creation"
          ],
          "typeOptions": [
            "Église",
            "Mosquée",
            "Terrain de foot",
            "Cimetière",
            "Antenne orange",
            "Centre d'alphabétisation",
            "Magasin de stockage",
            "Maison des jeunes",
            "Étang"
          ]
        }
      }
    },
    "Ouvrages": {
      "icon": "construction",
      "color": 0xFFFF9800,
      "entities": {
        "Pont": {
          "tableName": "ponts",
          "fields": [
            "piste_id",
            "x_pont",
            "y_pont",
            "situation_pont",
            "type_pont",
            "nom_cours_eau"
          ],
          "situationOptions": [
            "à réaliser",
            "en cours de réalisation",
            "existant",
            "ancien",
            "nouveau",
            "nouveau (1ans)"
          ],
          "typePontOptions": ["béton", "bois", "métallique", "autre"]
        },
        "Bac": {
          "tableName": "bacs",
          "fields": [
            "piste_id",
            "x_debut_traversee_bac",
            "y_debut_traversee_bac",
            "x_fin_traversee_bac",
            "y_fin_traversee_bac",
            "type_bac",
            "nom_cours_eau"
          ],
          "typeBacOptions": ["Manuel", "Motorisé"]
        },
        "Buse": {
          "tableName": "buses",
          "fields": ["piste_id", "x_buse", "y_buse"]
        },
        "Dalot": {
          "tableName": "dalots",
          "fields": ["piste_id", "x_dalot", "y_dalot", "situation_dalot"],
          "situationOptions": ["à réaliser", "en cours", "existant"]
        },
        "Passage Submersible": {
          "tableName": "passages_submersibles",
          "fields": [
            "piste_id",
            "x_debut_passage_submersible",
            "y_debut_passage_submersible",
            "x_fin_passage_submersible",
            "y_fin_passage_submersible",
            "type_materiau"
          ],
          "typeOptions": ["béton", "bloc de pierre", "gabion", "autre"]
        }
      }
    },
    "Points Critiques": {
      "icon": "warning",
      "color": 0xFFF44336,
      "entities": {
        "Point Critique": {
          "parentTable": "chaussees",
          "fields": [
            "piste_id",
            "x_point_critique",
            "y_point_critique",
            "type_point_critique"
          ],
          "typeOptions": ["nid de poule", "trou"]
        },
        "Point de Coupure": {
          "parentTable": "chaussees",
          "fields": [
            "piste_id",
            "x_point_coupure",
            "y_point_coupure",
            "causes_coupures"
          ],
          "causesOptions": ["Détruit (permanent)", "Inondé (temporaire)"]
        }
      }
    }
  };

  // Méthodes utilitaires exactement comme dans React Native
  static Map<String, dynamic>? getCategoryConfig(String category) {
    return config[category];
  }

  static Map<String, dynamic>? getEntityConfig(String category, String entity) {
    final categoryConfig = getCategoryConfig(category);
    if (categoryConfig != null) {
      final entities = categoryConfig['entities'] as Map<String, dynamic>?;
      return entities?[entity];
    }
    return null;
  }

  static List<String> getCategories() {
    return config.keys.toList();
  }

  static List<String> getEntitiesForCategory(String category) {
    final categoryConfig = getCategoryConfig(category);
    if (categoryConfig != null) {
      final entities = categoryConfig['entities'] as Map<String, dynamic>?;
      return entities?.keys.toList() ?? [];
    }
    return [];
  }

  static int getCategoryColor(String category) {
    final categoryConfig = getCategoryConfig(category);
    return categoryConfig?['color'] ?? 0xFF757575;
  }

  static String getCategoryIcon(String category) {
    final categoryConfig = getCategoryConfig(category);
    return categoryConfig?['icon'] ?? 'help';
  }

  static List<String> getTypeOptions(String category, String entity) {
    final entityConfig = getEntityConfig(category, entity);
    if (entityConfig != null) {
      return List<String>.from(entityConfig['typeOptions'] ?? []);
    }
    return [];
  }
}
