import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseSeeder {
  static Future<void> seedDatabase() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final WriteBatch batch = firestore.batch();

    //->Adventures
    final CollectionReference adventuresRef = firestore.collection('adventures');
    final List<Map<String, dynamic>> aventurasIniciales = [
      {
        "title": "Subida al Cristo de la Concordia al atardecer", //[cite: 1]
        "locName": "Cristo de la Concordia", //[cite: 1]
        "description": "Sube los escalones o toma el teleférico para ver caer el sol sobre la ciudad de la eterna primavera.", //[cite: 1]
        "valid_modes": ["solo", "pareja", "grupo"],
        "xpBase": 50,
        "costLevel": 1,
        "ubGeo": const GeoPoint(-17.38414, -66.13553)
      },
      {
        "title": "Paseo romántico en la Laguna Alalay", //[cite: 1]
        "locName": "Laguna Alalay", //[cite: 1]
        "description": "Una caminata tranquila rodeando la laguna, ideal para conversar y disfrutar de la brisa.", //[cite: 1]
        "valid_modes": ["pareja", "grupo"],
        "xpBase": 40,
        "costLevel": 1,
        "ubGeo": const GeoPoint(-17.4128, -66.1360)
      },
      {
        "title": "Desayuno con salteñas cochabambinas en la Av. Pando", //[cite: 1]
        "locName": "Avenida Pando", //[cite: 1]
        "description": "Empieza el día con el sabor más tradicional de la ciudad en una de las avenidas más icónicas.", //[cite: 1]
        "valid_modes": ["solo", "pareja", "grupo"],
        "xpBase": 60,
        "costLevel": 2,
        "ubGeo": const GeoPoint(-17.3754, -66.1523)
      },
      {
        "title": "Almuerzo con silpancho en La Casa del Gordo", //[cite: 2]
        "locName": "La Casa del Gordo", //[cite: 2]
        "description": "Un reto culinario para compartir uno de los platos más contundentes y deliciosos del valle.", //[cite: 2]
        "valid_modes": ["pareja", "grupo"],
        "xpBase": 80,
        "costLevel": 3,
        "ubGeo": const GeoPoint(-17.3800, -66.1600) 
      },
      {
        "title": "Paseo en bote en la laguna Corani", //[cite: 2]
        "locName": "Laguna Corani", //[cite: 2]
        "description": "Aléjense un poco de la ciudad y disfruten del paisaje boscoso y el clima fresco remando juntos.", //[cite: 2]
        "valid_modes": ["pareja"],
        "xpBase": 100,
        "costLevel": 3,
        "ubGeo": const GeoPoint(-17.2285, -65.8821)
      }
    ];

    for (var aventura in aventurasIniciales) {
      batch.set(adventuresRef.doc(), aventura);
    }

    //->Users
    final DocumentReference userRef = firestore.collection('users').doc('dummy_user_001');
    batch.set(userRef, {
      "username": "JugadorPrueba",
      "email": "prueba@daty.com",
      "nivelJugador": 1,
      "xpTotal": 0,
      "rachaDias": 0,
      "fechaRegistro": FieldValue.serverTimestamp(),
    });

    //->Solo Progress
    final DocumentReference soloRef = firestore.collection('solo_progress').doc('dummy_solo_001');
    batch.set(soloRef, {
      "id_user": "dummy_user_001",
      "id_adventure": "dummy_adv_001",
      "estado": "en_progreso",
      "fecha_inicio": FieldValue.serverTimestamp(),
    });

    //->Couples Progress
    final DocumentReference coupleRef = firestore.collection('couples_progress').doc('dummy_couple_001');
    batch.set(coupleRef, {
      "id_user_1": "dummy_user_001",
      "id_user_2": "dummy_user_002",
      "id_adventure": "dummy_adv_002",
      "estado": "completado",
      "fecha_completado": FieldValue.serverTimestamp(),
    });

    //->Groups Progress
    final DocumentReference groupRef = firestore.collection('groups_progress').doc('dummy_group_001');
    batch.set(groupRef, {
      "id_group": "group_alpha",
      "members_ids": ["dummy_user_001", "dummy_user_002", "dummy_user_003"],
      "id_adventure": "dummy_adv_003",
      "estado": "bloqueado",
    });

    //->Memorias
    final DocumentReference memoryRef = firestore.collection('memories').doc('dummy_mem_001');
    batch.set(memoryRef, {
      "id_user": "dummy_user_001",
      "imgUrl": "https://via.placeholder.com/300",
      "texto_recuerdo": "¡Mi primera salida usando Daty!",
      "source_mode": "solo",
      "id_adventure": "dummy_adv_001",
      "adventure_title": "Aventura de Prueba",
      "timestamp": FieldValue.serverTimestamp(),
    });

    //->Execute<-
    try {
      await batch.commit();
      debugPrint('Colecciones en Firestore');
    } catch (e) {
      debugPrint('Error en Firestore');
      rethrow;
    }
  }
}