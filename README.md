# PrestaControl (app Flutter)

App móvil para que un prestamista se registre, inicie sesión, registre el dinero que presta a sus clientes y marque
los préstamos cobrados. Consume la API REST protegida con JWT del repositorio `prestamoservice`.

**Integrantes**

- Junniors Williams Díaz Palacios
- Lorena Espinoza

Taller de Desarrollo de Aplicaciones Móviles — ED: Programación de una aplicación con Flutter (Ejercicio 2).

## Stack

- Flutter (canal stable), Dart 3 y Material 3.
- `http` para consumir la API y `flutter_secure_storage` para guardar el token.
- Paquete Android: `com.diaz.prestacontrol_app`.

## Estructura

```
lib/
├── config/servidor.dart       URL base según el servidor elegido (Render, USB o Wi-Fi)
├── models/                    Prestamo, Resumen y Sesion (con conversión desde/hacia JSON)
├── services/
│   ├── api_client.dart        Envía "Authorization: Bearer <token>" y traduce errores (401 → sesión expirada)
│   ├── auth_service.dart      Registro y login
│   ├── prestamo_service.dart  CRUD de préstamos y resumen
│   ├── token_storage.dart     Token en almacenamiento seguro
│   └── sesion_global.dart     Cierre de sesión y vuelta al login ante un 401
├── screens/                   Login, registro, servidor, lista y formulario
└── utils/                     Lectura del JWT y formatos (S/, fechas)
```

## Funcionalidades

Obligatorias:

- **Login y registro** con mensajes de error claros (los que devuelve la API).
- **Sesión persistente:** el token se guarda en almacenamiento seguro; al reabrir la app, si el token sigue vigente,
  entra directo a la lista.
- **Lista de préstamos:** cliente, DNI, monto, interés, total a cobrar y fecha de vencimiento.
- **Registrar y editar préstamo** con validaciones (DNI de 8 dígitos, monto mayor a 0, interés y fecha de vencimiento).
- **Marcar como pagado y anular** desde el menú de cada préstamo.
- **Cierre de sesión y token vencido:** botón para cerrar sesión; si la API responde 401, la app borra el token y
  vuelve al login.

Complementarias (las cuatro):

- **Resumen de cartera:** capital prestado, total por cobrar y ganancia esperada (`GET /prestamos/resumen`).
- **Filtros y morosos:** pestañas Por cobrar / Cobrados; los préstamos vencidos sin pagar se resaltan en rojo.
- **Aviso de expiración:** la app lee el `exp` del token y avisa cuando faltan menos de 10 minutos.
- **Búsqueda** por nombre o DNI del cliente.

## Servidor de la API

En la pantalla de login, el botón **Servidor** permite elegir:

| Opción | URL | Cuándo usarla |
|---|---|---|
| Render | `https://prestamoservice-diaz.onrender.com` | API publicada (por defecto) |
| USB | `http://localhost:8080` | API en la PC y celular por cable, tras `adb reverse tcp:8080 tcp:8080` |
| Wi-Fi | `http://<IP de la PC>:8080` | API en la PC y celular en la misma red |

El botón **Probar conexión** comprueba que la API responda. Android permite `http` sin cifrar
(`usesCleartextTraffic`) para las opciones locales; Render usa `https`.

## Ejecutar

```bash
flutter pub get
flutter run                 # en un emulador o celular conectado
flutter build apk --release # APK en build/app/outputs/flutter-apk/app-release.apk
```

> En Windows la ruta del proyecto no debe tener tildes ni otros caracteres no ASCII: Gradle no compila.
