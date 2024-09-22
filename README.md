# Application de démonstration pour la classification d'images

Ce README contient le nécessaire d'installation et d'utilisation de l'app.

## Prérequis

- Assurez-vous que ce projet soit contenu dans le même dossier que `img-classification-lib` car la dépendance vers ce package est faite localement.

**iOS**

- Assurez vous d'avoir installé `cocoapods` via [ce lien](https://cocoapods.org/)

## Installation

- Lancez la commande `pub get` afin d'installer les dépendances
  `img-classification-demo-app\ios\Runner`. Ajoutez-y les permissions suivante:
- **Pour iOS uniquement**: Rendez vous dans `img-classification-demo-app\ios` et lancez la commande `pod install` (nécessite cocoapods).
- **Pour iOS uniquement**: Ajouter les permissions d'accès à la galerie et l'appareil photo en modifiant le fichier `info.plist` dans

```xml
<dict>
    <!-- Other keys and configurations... -->

    <key>NSCameraUsageDescription</key>
    <string>Your app needs access to the camera to take photos and videos.</string>

    <key>NSPhotoLibraryUsageDescription</key>
    <string>Your app needs access to the photo library to select photos and videos.</string>
</dict>
```

- Lancez l'application

Si vous obtenez l'erreur `The method 'UnmodifiableUint8ListView' isn't defined for the class 'Tensor'` :

- **Pour Windows**: aller dans `C:\Users\MyUser\AppData\Local\Pub\Cache\hosted\pub.dev\tflite_flutter-0.10.4\lib\src`
- **Pour Mac**: aller dans `~/.pub-cache/hosted/pub.dev/tflite_flutter-0.10.4/lib/src`
- Ouvrez le fichier `tensor.dart`
- Modifiez le code suivant:

```dart
  Uint8List get data {
    final data = cast<Uint8>(tfliteBinding.TfLiteTensorData(_tensor));
    return UnmodifiableUint8ListView(
        data.asTypedList(tfliteBinding.TfLiteTensorByteSize(_tensor)));
  }
```

par:

```dart
Uint8List get data {
    final data = cast<Uint8>(tfliteBinding.TfLiteTensorData(_tensor));
    return data.asTypedList(tfliteBinding.TfLiteTensorByteSize(_tensor)).asUnmodifiableView();
  }
```

## Utilisation

### Inférence sans modification des options

- Sélectionnez un des trois modèles `ImageNet`, `ImageNetQuant` ou `Vespa Velutina` pour le charger en mémoire. Des logs informatifs sont visibles dans la console pour confirmer le chargement du modèle.
- Une fois le modèle chargé, vous pouvez sélectionner un cliché depuis la galerie ou prendre une photo directement depuis l'appareil.
- L'image apparaîtra en overlay avec la prédiction associée en-dessous.
- Appuyez sur `Close` pour fermer l'overlay
- Recommencez à volonté !

### Inférence avec modification des options

- Sélectionnez un des trois modèles
- Modifier les options d'inférence comme souhaité
- **Rechargez le modèle** avec les nouvelles options en appuyant sur `Reload Model`
- Sélectionner l'image depuis la source souhaitée.
- **ATTENTION:** Modifier la méthode de normalisation peut fausser les résultats de la prédictions. Seul le modèle `ImageNet` nécessite une méthode de normalisation `zero_to_one`.
- Pour réinitialiser les options d'un modèle, il suffit de rappuyer sur son nom dans la première ligne.

### Infos additionnelles

- Le modèle `ImageNet Quant` ne dispose pas de formattage en % de la prédiction, ceci dans le but de montrer que le résultat est quantifié entre 0 et 255.
- Sélectionner le modèle `Vespa Velutina` débloque une option supplémentaire correspondant au seuil que la valeur de prédiction doit dépasser pour attribuer la deuxième classe du modèle (ici, si l'image contient un frelon asiatique).
