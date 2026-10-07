Aquí tienes el estado real del tablero Kanban al día de hoy (fin de Daily 3), con el detalle completo de cada tarjeta según la columna en la que debe estar. Antes, un ajuste de criterio importante:

**Los RNF que sirven a una sola HU van dentro de esa tarjeta (como checklist), no como tarjeta aparte.** Por ejemplo, RNF-012 (seguridad de contraseñas) es un criterio de aceptación de HU-001, no una tarjeta independiente. Solo dejo como tarjeta aparte **RNF-005**, porque es transversal (afecta a varias pantallas/HU a la vez, no a una sola).

---

### **Columna: LISTO**

**HU-001: Autenticar usuario con credenciales del sistema**

* Assignee: Ancco Suaña, Bruno  
* Labels: `backend`, `epica:autenticacion`, `prioridad-alta`  
* Puntos: 5 | Riesgo: Bajo | Dato personal: Sí (credenciales de usuario)  
* Milestone: Sprint 1  
* Checklist: \[x\] Conexión a Supabase Auth · \[x\] Validación de credenciales reales · \[x\] RNF-012 — hashing nativo de Supabase verificado

**HU-002: Gestionar sesión y permisos por rol**

* Assignee: Sala Jimenez, Walter  
* Labels: `frontend`, `epica:autenticacion`, `prioridad-alta`  
* Puntos: 8 | Riesgo: Bajo | Dato personal: No  
* Milestone: Sprint 1  
* Checklist: \[x\] Lectura de rol desde tabla `profiles` · \[x\] RNF-001 — restricción de rutas con GoRouter · \[x\] Pruebas con los 3 roles (Almacén, Farmacia, Enfermería)

**HU-013: Gestionar catálogo de medicamentos e insumos médicos**

* Assignee: Ancco Suaña, Bruno  
* Labels: `backend`, `epica:inventario`, `prioridad-alta`  
* Puntos: 8 | Riesgo: Bajo | Dato personal: No  
* Milestone: Sprint 2  
* Checklist: \[x\] Consulta en tiempo real a PostgreSQL · \[x\] Búsqueda y filtro · \[ \] Acceso a RF-014 (registrar) — pendiente, va en Sprint 3

**HU-023: Visualizar stock actual de farmacia y almacén**

* Assignee: Ancco Suaña, Bruno  
* Labels: `backend`, `epica:inventario`, `prioridad-alta`  
* Puntos: 5 | Riesgo: Bajo | Dato personal: No  
* Milestone: Sprint 2  
* Checklist: \[x\] Vista consolidada Farmacia/Almacén · \[x\] Búsqueda y filtro por nombre/categoría

**HU-016: Editar datos de medicamento registrado**

* Assignee: Anampa, David  
* Labels: `backend`, `frontend`, `epica:inventario`, `prioridad-media`  
* Puntos: 5 | Riesgo: Bajo | Dato personal: No  
* Milestone: Sprint 2  
* Checklist: \[x\] Formulario precargado · \[x\] Guardado persistente vía `almacen_remote_datasource.dart`

---

### **Columna: EN PRUEBAS**

**HU-014 (parte 1): Registrar medicamento mediante escaneo GTIN** *(solo el escaneo, sin IA aún)*

* Assignee: Sala Jimenez, Walter  
* Labels: `frontend`, `mobile`, `epica:registro-inteligente`, `prioridad-alta`  
* Puntos: 8 | Riesgo: Medio — depende de calidad de cámara del dispositivo de prueba | Dato personal: No  
* Milestone: Sprint 2  
* Checklist: \[x\] Lectura GTIN offline con ML Kit · \[x\] RNF-011 — funciona sin conexión · \[ \] RF-015 (validación con IA/Gemini) — **no iniciado, queda para Sprint 3**  
* Nota: la tarjeta debe indicar explícitamente en su descripción que está **incompleta respecto al RF-014 original** (falta la foto \+ IA), para no reportarla como 100% Listo por error.

---

### **Columna: EN REVISIÓN**

**HU-029: Registrar solicitud de abastecimiento por faltantes de guardia**

* Assignee: Anampa, David  
* Labels: `backend`, `frontend`, `epica:inventario`, `prioridad-media`  
* Puntos: 5 | Riesgo: Bajo | Dato personal: No  
* Milestone: Sprint 2  
* Checklist: \[x\] Formulario de solicitud · \[x\] Estado "Pendiente" · \[ \] Validación final con datos reales de almacén

**HU-030: Visualizar y atender solicitudes de abastecimiento (almacén)**

* Assignee: Anampa, David  
* Labels: `backend`, `frontend`, `epica:inventario`, `prioridad-media`  
* Puntos: 8 | Riesgo: Medio — la transferencia atómica de stock necesita más pruebas de concurrencia | Dato personal: No  
* Milestone: Sprint 2  
* Checklist: \[x\] Listado de solicitudes pendientes · \[x\] Ajuste de cantidades a despachar · \[ \] Prueba de transferencia atómica (descuento almacén \+ suma farmacia)

---

### **Columna: EN PROGRESO**

*(vacía al cierre de Daily 3 — no hay nada activo sin terminar)*

---

### **Columna: SPRINT BACKLOG / PRODUCT BACKLOG (pendiente, no tocado aún)**

Estas deben quedar visibles en el backlog para que el tablero refleje honestamente lo que falta — no se mueven a Sprint Backlog hasta que se planifique el Sprint 3:

* RF-015 (validación IA/Gemini) — vinculado a HU-014, retomar primero  
* RF-003 a RF-012 (fichas de pedido completas)  
* RF-017 a RF-022 (kits de neonatología, gestión de usuarios)  
* RF-024 a RF-028 (entradas de stock, trazabilidad, PDF, Drive, dashboard)

---

### **Tarjeta transversal (no es HU)**

**RNF-005: Interfaz optimizada para dispositivos móviles**

* Assignee: Anampa, David  
* Labels: `ux`, `calidad-transversal`, `prioridad-alta`  
* Puntos: 3 | Riesgo: Bajo | Dato personal: No  
* Milestone: Sprint 1 (revisión continua en los siguientes)  
* Estado: En revisión  
* Descripción: criterio de calidad aplicado a todas las pantallas (componentes ≥44×44pt, navegación a una mano). No es una HU porque no entrega una función nueva, es un estándar de diseño que se valida en cada pantalla que se construye.

---

**Regla para mantener esto ordenado de aquí en adelante:** cada vez que una HU se mueva de columna, su checklist interno debe reflejar qué sub-tarea específica se completó — así el tablero no dice solo "se movió", dice *por qué* se movió, igual que corregimos en el daily.

cuales deben ser las columnas de mi project en base a lo que me dices?

En base a todo lo que hemos trabajado (y a los WIP que ya vienen usando en el tablero real que compartiste), estas son las **6 columnas** que debe tener tu Project:

### **Columnas del Project**

**1\. Product Backlog**

* Todas las HU (HU-001 a HU-030) y RNF transversales sin priorizar aún a un sprint específico.  
* Sin WIP (no limita, es el repositorio general).

**2\. Sprint Backlog**

* HU/RNF ya comprometidas en el sprint activo, pero que todavía nadie empezó a trabajar.  
* WIP: 10 (como vimos en tu ejemplo real).

**3\. En progreso**

* Lo que un integrante está desarrollando activamente en este momento.  
* WIP: 3 (límite por tablero completo, o 2 si prefieres limitarlo por persona — tú has usado ambos criterios, conviene fijar uno solo).

**4\. En revisión**

* Terminado por el desarrollador, pendiente de que otro del equipo lo revise (Pull Request, o que la jefa de farmacia valide el flujo).  
* WIP: 3\.

**5\. En pruebas**

* Ya revisado, pasando pruebas funcionales (QA manual, prueba con datos reales, prueba de conectividad/offline, etc.).  
* WIP: 2\.

**6\. Listo**

* Cumple la Definition of Done: código en main/develop, probado, documentado.  
* Sin WIP (es la meta final, no restringe).

---

### **Por qué estas 6 y no menos/más**

* Es el **mismo set de columnas** que ya usaste en todos los dailys que armamos (Sprint backlog → En progreso → En revisión → En pruebas → Listo), solo le agrego **Product Backlog** al inicio porque la necesitas para los ítems que aún no entran a ningún sprint (como RF-015, RF-003 a RF-012, etc. que identificamos como pendientes).  
* Separar **"En revisión" de "En pruebas"** es clave para tu proyecto porque tienen significados distintos: revisión \= código correcto (PR aprobado); pruebas \= funciona de verdad (ej. que el escaneo GTIN lea códigos reales, que la transferencia de stock sea atómica). Si las juntas en una sola columna, pierdes visibilidad de en qué etapa exacta está cada ítem — algo que ya vimos que importa mucho en HU-030, donde el código está aprobado pero falta la prueba de concurrencia.  
* **No agregues una columna "Bloqueado"** aparte: un impedimento se documenta en la tabla de Impedimentos del daily y se marca en la descripción de la tarjeta, pero la tarjeta se queda en su columna actual (ej. "En progreso — bloqueado"), no se mueve a una columna especial, porque eso rompe la lógica de flujo del Kanban.

