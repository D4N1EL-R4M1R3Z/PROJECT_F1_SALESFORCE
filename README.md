# Speed League - Liga Fantasy Fórmula 1

## Descripción del Proyecto

Plataforma Fantasy F1 desarrollada en Salesforce para Speed League, permitiendo a usuarios internos y externos crear equipos virtuales de pilotos y competir en función del rendimiento real en la temporada 2024.

## Equipo de Desarrollo

### Equipo Técnico
- **Daniel Ramírez** - Lead Developer
- **Mateo Guzmán** - Developer
- **Juan Oliveros** - Consultor Funcional

### Roles y Responsabilidades
- **Lead Developer**: Coordinación del equipo, creación de clases apex.
- **Developer**: Implementación de funcionalidades, integraciones apex y automatizaciones
- **Consultor Funcional**: Análisis de requisitos, configuración de objetos y validación de procesos

## Arquitectura del Sistema

### Diagrama de Flujo - Proceso Principal

```
┌─────────────────────────────────────────────────────────────┐
│                    API Externa F1 (Ergast)                  │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ Integración HTTP
                             ↓
┌─────────────────────────────────────────────────────────────┐
│      Apex Queueable Class + Batch Class(Carga de Datos)     │
│     • Circuitos  • Pilotos  • Escuderías  • Resultados      │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────┐
│                        Modelo de Datos                      │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌──────────┐    │
│  │ Circuit  │  │  Driver  │  │Constructor│  │  Result  │    │
│  └──────────┘  └──────────┘  └───────────┘  └──────────┘    │
│        │            │              │              │         │
│        └────────────┴──────────────┴──────────────┘         │
│                             │                               │
│                  ┌──────────▼──────────┐                    │
│                  │   Team Fantasy      │                    │
│                  └─────────────────────┘                    │
└────────────────────────────┬────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ↓                             ↓
┌──────────────────────┐       ┌─────────────────────────┐
│   Experience Cloud   │       │Fórmula 1 - Liga Fantasy │
│  (Usuarios Externos) │       │   (Usuarios Internos)   │
└──────────────────────┘       └─────────────────────────┘
```

### Diagrama de Flujo - Creación de Equipo Fantasy

```
┌────────────┐
│   Inicio   │
└─────┬──────┘
      │
      ↓
┌─────────────────────────┐
│ Usuario selecciona      │
│ 5 pilotos + 2 escuderías│
└─────┬───────────────────┘
      │
      ↓
┌─────────────────────────┐
│ Validación presupuesto  │◄───── Trigger: TeamFantasyValidation
│ (Máximo 100M)           │
└─────┬───────────────────┘
      │
      ├─── NO → [Mensaje de Error]
      │
      ↓ SI
┌─────────────────────────┐
│ Creación de registros   │
│ en objeto intermedio    │
└─────┬───────────────────┘
      │
      ↓
┌─────────────────────────┐
│ Flow: Cálculo de        │
│ puntuación inicial      │
└─────┬───────────────────┘
      │
      ↓
┌─────────────────────────┐
│ Envío de email a        │
│ administrador           │
└─────┬───────────────────┘
      │
      ↓
┌────────────┐
│    Fin     │
└────────────┘
```

### Diagrama de Flujo - Actualización de Puntuaciones

```
┌────────────────┐
│ Nueva Carrera  │
│  Finalizada    │
└────┬───────────┘
     │
     ↓
┌──────────────────────┐
│ API: Obtener         │
│ resultados carrera   │
└────┬─────────────────┘
     │
     ↓
┌──────────────────────┐
│ Batch: Crear/        │
│ Actualizar Results   │
└────┬─────────────────┘
     │
     ↓
┌──────────────────────┐
│ Flow: Calcular       │
│ puntos por posición  │
└────┬─────────────────┘
     │
     ├───────────────────┐
     │                   │
     ↓                   ↓
┌─────────────┐   ┌──────────────┐
│ Puntos Base │   │Puntos Extras │
│ (Top 10)    │   │• Pole        │
│             │   │• Vuelta rápida│
└─────┬───────┘   │• Q2/Q3       │
      │           │• Pit-stops   │
      │           └──────┬───────┘
      │                  │
      └───────┬──────────┘
              │
              ↓
┌──────────────────────────┐
│ Actualización puntos     │
│ Equipos Fantasy          │
└──────────────────────────┘
```

## Modelo de Datos

### Objetos Personalizados

#### 1. Circuit (Circuito)
- **Campos principales**: 
  - Name (Nombre del circuito)
  - circuitId__c (ID externo)
  - Location__c (Geolocalización)
  - locality__c, country__c
  - url__c

#### 2. Driver (Piloto)
- **Campos principales**:
  - Name (Nombre completo)
  - driverId__c (ID externo)
  - number__c (Número del piloto)
  - nationality__c
  - Total_Points__c (Puntos totales)
  - Value__c (Valor en millones)
- **Relaciones**: 
  - Constructor__c (Lookup a Escudería)

#### 3. Constructor (Escudería)
- **Campos principales**:
  - Name (Nombre de la escudería)
  - constructorId__c (ID externo)
  - nationality__c
  - Total_Points__c
  - Value__c (Valor en millones)

#### 4. Result (Resultado de Carrera)
- **Campos principales**:
  - position__c (Posición final)
  - points__c (Puntos obtenidos)
  - grid__c (Posición de salida)
  - FastestLap__c (Vuelta más rápida)
- **Relaciones**:
  - Driver__c (Lookup a Piloto)
  - Race__c (Lookup a Carrera)

#### 5. Race (Carrera)
- **Campos principales**:
  - Name (Nombre de la carrera)
  - raceId__c
  - round__c (Número de carrera)
  - date__c, time__c
- **Relaciones**:
  - Circuit__c (Lookup a Circuito)

#### 6. Team_Fantasy (Equipo Fantasy)
- **Campos principales**:
  - Name
  - Total_Points__c (Puntos totales)
  - User__c (Lookup a Usuario)
  - Budget_Used__c (Presupuesto utilizado)
- **Objeto intermedio**: Team_Fantasy_Driver__c (para relación many-to-many)

#### 7. Sprint
- **Campos principales**:
  - Name
  - sprintId__c
  - date__c, time__c
- **Relaciones**:
  - Circuit__c

## Funcionalidades Implementadas

### 1. Integración con API Externa
- **Clase Apex**: `CircuitController`, `DriverController`, `ConstructorController`
- **Batch Classes**: Carga automatizada de datos desde la API de Ergast
- **Scheduled Jobs**: Actualización programada de información

### 2. Gestión de Equipos Fantasy
- **Trigger**: `TeamFantasyValidation` - Validación de presupuesto de 100M
- **Lightning Web Components**: Interfaz de selección de pilotos y escuderías
- **Flow**: Cálculo automático de puntuaciones

### 3. Sistema de Puntuación

#### Puntos Base (Top 10)
| Posición | Puntos |
|----------|--------|
| 1º       | 25     |
| 2º       | 18     |
| 3º       | 15     |
| 4º       | 12     |
| 5º       | 10     |
| 6º       | 8      |
| 7º       | 6      |
| 8º       | 4      |
| 9º       | 2      |
| 10º      | 1      |

#### Puntos Adicionales (Ejercicios Opcionales)

**Puntos por Pit-Stops**
| Posición        | Puntos |
|-----------------|--------|
| 1º más rápido   | 10     |
| 2º más rápido   | 5      |
| 3º más rápido   | 3      |

**Puntos por Clasificación (Q2/Q3)**
| Escenario                  | Puntos |
|----------------------------|--------|
| Ningún piloto en Q2        | 0      |
| Un piloto en Q2            | 1      |
| Ambos pilotos en Q2        | 3      |
| Un piloto en Q3            | 5      |
| Ambos pilotos en Q3        | 10     |

**Penalizaciones**
- No completar carrera: -10 puntos

### 4. Experience Cloud Portal
- **URL**: Formula 1 Portal (Experience Cloud)
- **Perfiles**:
  - Entrenador Fantasy Portal (Externos)
  - Entrenador Fantasy Interno
- **Funcionalidades**:
  - Registro y autenticación
  - Creación de equipos
  - Visualización de clasificaciones
  - Dashboard con estadísticas

### 5. Automatizaciones
- **Flows**: 
  - Cálculo de puntuaciones post-carrera
  - Actualización de clasificaciones
  - Validaciones de equipo
- **Process Builder**: Notificaciones automáticas
- **Email Templates**: Confirmación de creación de equipo

## Tecnologías Utilizadas

- **Plataforma**: Salesforce
- **Lenguaje**: Apex
- **Frontend**: Lightning Web Components (LWC)
- **Automatización**: Flow Builder, Process Builder
- **Integración**: REST API (Callouts HTTP)
- **Portal**: Experience Cloud
- **Testing**: Apex Test Classes (cobertura >75%)

## Instalación y Configuración

### Requisitos Previos
- Org de Salesforce (Developer Edition o superior)
- Permisos de administrador
- Acceso a la API de Ergast

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone [URL-del-repositorio]
cd speed-league-fantasy-f1
```

2. **Autenticarse en Salesforce**
```bash
sfdx auth:web:login -a DevOrg
```

3. **Deploy de metadatos**
```bash
sfdx force:source:deploy -p force-app/main/default -u DevOrg
```

4. **Configurar Remote Site Settings**
- Setup → Security → Remote Site Settings
- Añadir: https://api.jolpi.ca

5. **Ejecutar carga inicial de datos**
```apex
// En Developer Console
CircuitController.saveCircuits();
DriverController.saveDrivers();
ConstructorController.saveConstructors();
```

6. **Configurar Experience Cloud**
- Setup → Digital Experiences → All Sites
- Activar y configurar el sitio "Formula 1 DMJ"

7. **Asignar perfiles y permisos**
- Crear usuarios con perfiles correspondientes
- Asignar Permission Sets necesarios

## Estructura del Proyecto

```
force-app/main/default/
├── applications/           # Apps personalizadas
├── classes/               # Clases Apex
│   ├── CircuitController.cls
│   ├── DriverController.cls
│   ├── ConstructorController.cls
│   ├── *Batch.cls
│   └── *Job.cls
├── triggers/              # Triggers Apex
│   └── TeamFantasyValidation.trigger
├── lwc/                   # Lightning Web Components
├── flows/                 # Flows automatizados
├── layouts/               # Page Layouts
├── objects/               # Objetos personalizados
│   ├── Circuit__c/
│   ├── Driver__c/
│   ├── Constructor__c/
│   ├── Result__c/
│   ├── Race__c/
│   ├── Team_Fantasy__c/
│   └── Sprint__c/
├── experiences/           # Experience Cloud config
├── profiles/             # Perfiles de usuario
├── permissionsets/       # Permission Sets
└── tabs/                 # Tabs personalizadas
```

## Gestión del Proyecto - Metodología SCRUM

### Sprint 1 (18 Nov - 22 Nov)

| Estado | Tarea | Responsable | Descripción |
|--------|-------|-------------|-------------|
| ✅ | Análisis de requisitos | Juan Oliveros | Revisión del documento del proyecto y definición de alcance |
| ✅ | Diseño del modelo de datos | Juan Oliveros | Definición de objetos, campos y relaciones |
| ✅ | Configuración Remote Site | Daniel Ramírez | Configuración de acceso a API externa |
| ✅ | Desarrollo integración API | Daniel Ramírez | Clases Apex para consumir API Ergast |
| ✅ | Testing integración | Mateo Guzmán | Pruebas de conectividad y respuesta API |

### Sprint 2 (25 Nov - 29 Nov)

| Estado | Tarea | Responsable | Descripción |
|--------|-------|-------------|-------------|
| ✅ | Creación objetos Core | Juan Oliveros | Circuit, Driver, Constructor, Result |
| ✅ | Creación objeto Team Fantasy | Juan Oliveros | Objeto principal y objeto intermedio |
| ✅ | Batch Classes circuitos | Daniel Ramírez | Batch para carga masiva de circuitos |
| ✅ | Batch Classes pilotos | Mateo Guzmán | Batch para carga masiva de pilotos |
| ✅ | Batch Classes escuderías | Mateo Guzmán | Batch para carga masiva de constructores |
| ✅ | Configuración de perfiles | Juan Oliveros | Entrenador Fantasy Portal, Interno, Admin |
| ✅ | Testing batch classes | Daniel Ramírez | Test classes con >75% cobertura |

### Sprint 3 (2 Dic - 6 Dic)

| Estado | Tarea | Responsable | Descripción |
|--------|-------|-------------|-------------|
| ✅ | Batch Classes resultados | Daniel Ramírez | Integración de resultados de carreras |
| ✅ | Batch Classes sprints | Mateo Guzmán | Carga de información de sprints |
| ✅ | Scheduled Jobs | Daniel Ramírez | Automatización de ejecución de batches |
| ✅ | Trigger validación presupuesto | Mateo Guzmán | TeamFantasyValidation trigger |
| ✅ | Flow cálculo puntuaciones | Juan Oliveros | Automatización de cálculo de puntos |
| ✅ | Customización layouts | Juan Oliveros | Page layouts para objetos principales |
| ✅ | App Builder configuración | Juan Oliveros | Creación de app Lightning personalizada |

### Sprint 4 (9 Dic - Entrega Final)

| Estado | Tarea | Responsable | Descripción |
|--------|-------|-------------|-------------|
| ✅ | Experience Cloud setup | Juan Oliveros | Configuración inicial del portal |
| ✅ | LWC selección de equipo | Mateo Guzmán | Componente para crear Team Fantasy |
| ✅ | LWC visualización pilotos | Mateo Guzmán | Componente de catálogo de pilotos |
| ✅ | Dashboard clasificaciones | Juan Oliveros | Reports y dashboards de puntuaciones |
| ✅ | Email templates | Juan Oliveros | Plantilla de confirmación de equipo |
| ✅ | Ejercicio opcional: Presupuesto | Daniel Ramírez | Sistema de valores aleatorios |
| ✅ | Ejercicio opcional: Pit-stops | Daniel Ramírez | Puntos adicionales por pit-stops |
| ✅ | Ejercicio opcional: Q2/Q3 | Mateo Guzmán | Puntos por clasificación |
| ✅ | Testing integral | Equipo Completo | Pruebas end-to-end de toda la solución |
| ✅ | Documentación técnica | Daniel Ramírez | README y documentación de código |
| ✅ | Preparación demo | Equipo Completo | Preparación de presentación final |

## Testing

### Cobertura de Código
- **Objetivo**: >75% de cobertura
- **Actual**: 82% (cumplido)

### Casos de Prueba Principales
1. Validación de presupuesto en Team Fantasy
2. Cálculo correcto de puntuaciones
3. Integración con API externa
4. Batch jobs execution
5. Flow de automatización

## Problemas Conocidos y Soluciones

### Problema 1: Límite de Callouts en Batch
**Solución**: Implementación de Scheduled Jobs que ejecutan batches con size=1

### Problema 2: Validación de presupuesto compleja
**Solución**: Trigger con lógica agregada para validar suma de valores

### Problema 3: Actualización de puntuaciones en tiempo real
**Solución**: Flows activados por actualización de Results

## Roadmap Futuro

### Fase 2 (Futuras mejoras)
- [ ] Ligas privadas entre usuarios
- [ ] Sistema de transferencias entre carreras
- [ ] Predicciones con IA de rendimiento
- [ ] Notificaciones push en tiempo real
- [ ] App móvil nativa
- [ ] Integración con redes sociales

## Lecciones Aprendidas

1. **Coordinación del equipo**: La comunicación constante entre desarrolladores y consultor funcional fue clave para el éxito.
2. **Priorización**: Implementar funcionalidades core antes de opcionales permitió entregar valor temprano.
3. **Testing continuo**: Realizar pruebas en cada sprint evitó deuda técnica.
4. **Documentación**: Mantener documentación actualizada facilitó la colaboración.

## Recursos Adicionales

- [Salesforce Developer Guide](https://developer.salesforce.com/docs)
- [Formula One API Documentation](https://ergast.com/mrd/)
- [Experience Cloud Documentation](https://help.salesforce.com/s/articleView?id=sf.networks_overview.htm)
- [Lightning Web Components Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)

## Contacto y Soporte

Para consultas sobre el proyecto:
- **Daniel Ramírez** (Lead Developer): daniel.ramirez@inetum.com
- **Mateo Guzmán** (Developer): mateo.guzman@inetum.com
- **Juan Oliveros** (Consultor Funcional): juan.oliveros@inetum.com

## Licencia

Este proyecto fue desarrollado como parte del programa Salesforce Academy de Inetum.

---

**Desarrollado por**: Equipo DMJ - Salesforce Academy Inetum
**Período**: 18 Noviembre - 9 Diciembre 2024
**Cliente**: Speed League
**Proyecto**: Liga Fantasy Fórmula 1
