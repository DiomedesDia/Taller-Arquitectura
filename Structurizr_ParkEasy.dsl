workspace "ParkEasy - Sistema de Gestión de Parqueaderos" "Arquitectura del sistema ParkEasy - Grupo 4" {

    model {
        
        # =================================================================
        # PERSONAS
        # =================================================================
        
        driver = person "Conductor" "Persona que busca parquear su vehículo en uno de los parqueaderos"
        
        operator = person "Operador" "Personal en casetas que registra entradas/salidas manuales y gestiona incidencias"
        
        administrator = person "Administrador" "Gerente que monitorea la operación, consulta reportes y configura tarifas"
        
        # =================================================================
        # SISTEMAS EXTERNOS
        # =================================================================
        
        lprSystem = softwareSystem "Sistema de Cámaras LPR" "Sistema de reconocimiento de placas vehiculares con API REST" {
            tags "External System"
        }
        
        legacyBilling = softwareSystem "Sistema de Cobro Legacy" "Sistema VB6 que registra transacciones mediante API SOAP" {
            tags "External System"
        }
        
        paymentGateway = softwareSystem "Wompi" "Pasarela de pagos para tarjetas, Nequi y Daviplata" {
            tags "External System"
        }
        
        notificationService = softwareSystem "Servicios de Notificación" "SendGrid y Twilio para envío de emails y SMS" {
            tags "External System"
        }
        
        dian = softwareSystem "DIAN" "Sistema de facturación electrónica en Colombia" {
            tags "External System"
        }
        
        # =================================================================
        # SISTEMA PRINCIPAL
        # =================================================================
        
        parkEasy = softwareSystem "ParkEasy" "Sistema de gestión de parqueaderos que permite reservas, pagos y administración" {
            
            # ===================== WEB =====================
            webApp = container "Aplicación Web" "Interfaz para conductores, operadores y administradores" "React PWA" {
                tags "Web Browser"
            }
            
            # ===================== SERVICIOS =====================
            
            parkingService = container "Parking Service" "Gestiona entradas, salidas y reconocimiento LPR" "Node.js + Express" {
                tags "Service"
                
                parkingController = component "Parking Controller" "Expone endpoints de entrada y salida" "Controller"
                parkingLogic = component "Parking Service Logic" "Lógica de negocio de parqueadero" "Service"
                parkingRepository = component "Parking Repository" "Acceso a datos de parqueadero" "Repository"
            }
            
            bookingService = container "Booking Service" "Gestiona reservas anticipadas" "Node.js + Express" {
                tags "Service"
            }
            
            paymentService = container "Payment Service" "Procesa pagos e integra con Wompi y sistema legacy" "Node.js + Express" {
                tags "Service"
            }
            
            billingService = container "Billing Service" "Genera facturación electrónica e integra con DIAN" "Node.js + Express" {
                tags "Service"
            }
            
            database = container "Base de Datos Principal" "Almacena usuarios, reservas, transacciones y facturas" "PostgreSQL" {
                tags "Database"
            }
        }
        
        # =================================================================
        # RELACIONES - CONTEXTO
        # =================================================================
        
        driver -> parkEasy "Busca disponibilidad, hace reservas y paga" "HTTPS"
        operator -> parkEasy "Registra entradas/salidas manuales" "HTTPS"
        administrator -> parkEasy "Consulta reportes y configura tarifas" "HTTPS"
        
        parkEasy -> lprSystem "Obtiene placas de vehículos" "REST/JSON"
        parkEasy -> legacyBilling "Registra transacciones" "SOAP/XML"
        parkEasy -> paymentGateway "Procesa pagos" "REST/JSON"
        parkEasy -> notificationService "Envía notificaciones" "REST/JSON"
        parkEasy -> dian "Genera facturación electrónica" "REST/JSON"
        
        # =================================================================
        # RELACIONES - CONTENEDORES
        # =================================================================
        
        driver -> webApp "Usa para reservar y pagar" "HTTPS"
        operator -> webApp "Usa para registrar operaciones manuales" "HTTPS"
        administrator -> webApp "Usa para gestión y reportes" "HTTPS"
        
        webApp -> parkingService "Gestiona entradas/salidas" "HTTP/JSON"
        webApp -> bookingService "Gestiona reservas" "HTTP/JSON"
        webApp -> paymentService "Procesa pagos" "HTTP/JSON"
        webApp -> billingService "Consulta facturación" "HTTP/JSON"
        
        parkingService -> database "Lee/escribe entradas y ocupación" "TCP/PostgreSQL"
        bookingService -> database "Lee/escribe reservas" "TCP/PostgreSQL"
        paymentService -> database "Registra pagos" "TCP/PostgreSQL"
        billingService -> database "Almacena facturas" "TCP/PostgreSQL"
        
        parkingService -> lprSystem "Obtiene placa" "HTTP/JSON"
        paymentService -> paymentGateway "Procesa pago" "HTTP/JSON"
        paymentService -> legacyBilling "Registra transacción" "SOAP/XML"
        billingService -> dian "Envía factura" "HTTP/JSON"
        
        paymentService -> notificationService "Envía confirmación de pago" "HTTP/JSON"
        bookingService -> notificationService "Envía confirmación de reserva" "HTTP/JSON"
        
        # =================================================================
        # RELACIONES - COMPONENTES
        # =================================================================
        
        parkingController -> parkingLogic "Llama lógica de negocio"
        parkingLogic -> parkingRepository "Accede a datos"
        parkingRepository -> database "Consulta y persiste datos"
        
    }

    views {
        
        systemContext parkEasy "SystemContext" {
            include *
            autolayout lr
        }
        
        container parkEasy "Containers" {
            include *
            autolayout lr
        }
        
        component parkingService "ComponentsParkingService" {
            include *
            autolayout lr
        }
        
        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            
            element "External System" {
                background #999999
                color #ffffff
            }
            
            element "Service" {
                background #1168bd
                color #ffffff
            }
            
            element "Web Browser" {
                shape WebBrowser
                background #438dd5
                color #ffffff
            }
            
            element "Database" {
                shape Cylinder
                background #438dd5
                color #ffffff
            }
        }
        
        theme default
    }
}