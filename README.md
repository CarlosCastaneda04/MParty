MParty - App de Gestión de Torneos

MParty es una aplicación nativa para iOS desarrollada en SwiftUI que conecta a jugadores y organizadores de torneos (juegos de mesa, videojuegos, etc.). Permite gestionar inscripciones, pagos simulados, rankings globales y perfiles de usuario con roles diferenciados.

Tecnologías Utilizadas

Lenguaje: Swift 5.0+

Framework UI: SwiftUI

Arquitectura: MVVM (Model - View - ViewModel)

IDE: Xcode (versión 15.0 o superior recomendada)

Backend (BaaS): Firebase

Authentication: Gestión de usuarios y roles.

Cloud Firestore: Base de datos NoSQL en tiempo real.

Firebase Storage: Almacenamiento de imágenes (perfiles y banners).

Gestor de Dependencias: Swift Package Manager (SPM)

Requisitos Previos

Para ejecutar este proyecto necesitas:

Una Mac con macOS actualizado.

Xcode instalado.

Una cuenta de Google (para configurar Firebase).

Guía de Instalación y Configuración

Sigue estos pasos para ejecutar la app en una nueva Mac:

1. Configuración de Firebase (Crucial)

La app necesita conectarse a tu base de datos. Si estás clonando este proyecto, el archivo de credenciales (GoogleService-Info.plist) no suele incluirse por seguridad. Debes generarlo:

Ve a la Consola de Firebase.

Crea un nuevo proyecto llamado "MParty" (o usa el existente).

Añade una app iOS al proyecto:

Registra el Bundle Identifier exacto que tienes en Xcode (ej: MPartyCMCJK.MParty).

Descarga el archivo GoogleService-Info.plist.

Arrastra este archivo a la carpeta raíz de tu proyecto en Xcode (dentro de la carpeta amarilla MParty). Asegúrate de marcar la casilla "Copy items if needed".

2. Habilitar Servicios en Firebase

Para que la app no de errores, debes activar estos servicios en la consola web:

Authentication: Ve a Authentication > Sign-in method y habilita "Correo electrónico/Contraseña".

Firestore Database: Crea la base de datos en "Modo de Prueba" (Test Mode). Selecciona una ubicación cercana (ej. us-central1).

Nota: El índice compuesto para el Ranking se creará automáticamente siguiendo el enlace que aparecerá en la consola de Xcode si es necesario.

Storage: Habilita Storage en "Modo de Prueba".

3. Abrir el Proyecto en Xcode

Abre el archivo MParty.xcodeproj.

Espera a que Xcode descargue automáticamente las dependencias de Firebase ("Resolving Package Graph"). Verás una barra de progreso en la parte superior derecha.

4. Configurar la Firma (Signing)

Aunque uses el simulador, Xcode necesita un equipo de desarrollo:

Haz clic en el proyecto azul MParty (arriba a la izquierda).

Selecciona el Target MParty.

Ve a la pestaña Signing & Capabilities.

En Team, selecciona tu cuenta personal (o dale a "Add Account..." e inicia sesión con tu Apple ID).

Ejecutar la App

En la parte superior de Xcode, selecciona un simulador (recomendado: iPhone 15 Pro o iPhone 16).

Presiona el botón Play o usa el atajo Cmd + R.

La app debería compilar e iniciarse en el simulador.

Estructura del Proyecto (MVVM)

El código está organizado siguiendo el patrón de diseño MVVM para mantenerlo limpio y escalable:

Models: Estructuras de datos (User, Event, Participant). Aquí se define qué datos usamos.

Views: Las pantallas y componentes visuales (LoginView, HomeView, EventDetailView). Aquí se define cómo se ve la app.

ViewModels: La lógica de negocio (AuthViewModel, EventViewModel, RankingViewModel). Aquí se conecta Firebase con la vista.

Components: Elementos reutilizables de UI (SecurePasswordView, tarjetas personalizadas).

Solución de Problemas Comunes

Error "No such module Firebase...": Ve al menú superior: Product > Clean Build Folder (o Shift + Cmd + K). Espera unos segundos y vuelve a ejecutar.

El Ranking no carga: Mira la consola de debug en Xcode (parte inferior). Si ves un mensaje con un enlace que empieza con "https://console.firebase.google.com/...", haz clic en él para crear el índice necesario en Firebase automáticamente.

Error de "Bundle Identifier": Si cambias de Mac, asegúrate de que el "Bundle Identifier" en la pestaña Signing coincida con el que registraste en Firebase. Si lo cambias en Xcode, debes descargar un nuevo GoogleService-Info.plist.
