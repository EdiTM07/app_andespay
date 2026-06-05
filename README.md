# SmartBank EC (AndesPay)

Una aplicación móvil bancaria completa construida con Flutter y Firebase, que demuestra principios avanzados de arquitectura, diseño UI/UX, y seguridad.

## Características Principales

- **Autenticación Segura:** Login con Email/Password y Google Sign-In, verificación con PIN local de 4 dígitos usando SHA-256.
- **Gestión de Cuentas:** Soporte para cuentas de ahorros con balances en tiempo real usando Cloud Firestore.
- **Transferencias P2P:** Flujo transaccional atómico bidireccional seguro mediante `runTransaction` de Firestore. Animaciones Hero y comprobantes de pago.
- **Pagos con Código QR:** Generador dinámico de códigos QR (con monto fijo o libre) y escáner integrado en la app.
- **Notificaciones en Tiempo Real:** Historial de alertas de seguridad, transferencias recibidas y promociones con contadores "no leídos".
- **Diseño UI/UX "Glassmorphism":** Paleta de colores esmeralda corporativa, transiciones suaves, tarjetas esqueleto (shimmer) durante la carga y microinteracciones en botones.

## Estructura del Proyecto

El proyecto sigue una arquitectura **Feature-Driven** limpia y escalable:

```
lib/
├── app/                  # Configuraciones globales (MultiProvider, Shell de navegación)
├── core/
│   ├── constants/        # Colores, temas, strings de la app
│   ├── router/           # GoRouter para navegación declarativa
│   ├── utils/            # Validadores, Helpers de seguridad, Formateadores
│   └── widgets/          # Componentes reutilizables (Botones, TextFields, Modals)
├── features/
│   ├── accounts/         # Lógica de cuentas y saldos
│   ├── auth/             # Autenticación, registro, PIN setup
│   ├── dashboard/        # Pantalla principal (SliverAppBar, historial)
│   ├── notifications/    # Centro de notificaciones y alertas
│   ├── profile/          # Gestión de perfil de usuario
│   ├── qr_payments/      # Escáner y generador QR
│   └── transfers/        # Flujos de transferencia de dinero
└── services/             # Servicios de bajo nivel (Auth Service, Firestore)
```

## Configuración y Ejecución

1. Asegúrate de tener **Flutter SDK** (>= 3.0.0) instalado.
2. Clona este repositorio y navega a su directorio.
3. Ejecuta `flutter pub get` para instalar dependencias.
4. El proyecto utiliza **Firebase**. Debes generar y agregar los archivos `google-services.json` (Android) y/o `GoogleService-Info.plist` (iOS) en sus respectivas carpetas utilizando **FlutterFire CLI** (`flutterfire configure`).
5. (Opcional) Si configuras Firestore, asegúrate de aplicar las reglas de seguridad provistas en `firestore.rules`.
6. Ejecuta `flutter run` para probar en tu emulador o dispositivo físico.

## Tecnologías y Paquetes Destacados

- **Gestión de Estado:** `provider` (Clean, simple y efectivo para esta escala).
- **Enrutamiento:** `go_router` (Soporte nativo para BottomNavigationBar con historial persistente mediante `StatefulShellRoute`).
- **Base de Datos & Auth:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`.
- **UI:** `google_fonts`, `shimmer` (para loading states), `qr_flutter` & `mobile_scanner` (pagos QR), `confetti` (celebración al finalizar pagos).

## Seguridad

- Todos los PINs de confirmación de pagos no se almacenan en texto plano en la nube, se manejan hashes locales usando `crypto` (SHA-256).
- Validaciones estáticas de cliente y transacciones atómicas evitan carreras de saldo (`race conditions`).
- Reglas de Firestore previenen el acceso no autorizado a los datos privados del usuario.

---
*Desarrollado con Flutter 💙*
