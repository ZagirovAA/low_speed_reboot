#!/usr/bin/env lua

###################################################
#                                                 #
#               MikroTik Low Speed Reboot         #
#                                                 #
###################################################
#                                                 #
# Скрипт перезагрузки оборудования от MikroTik в  # 
# случае падения скорости интерфейса до указанной #
#                                                 #
###################################################


###################################################
## Инициализация
###################################################

:global IFACE "ether1"
:global LOWSPEED 10
:global SPEEDTYPE "M"
:global TYPES [:toarray "Mbps, Gbps"]


###################################################
## Функции
###################################################

# Функция получения состояния интерфейса
:local getIfState do={
    :global IFACE
    :local ifDisabled
    :set $ifDisabled [/interface ethernet get $IFACE disabled]
    :if ($ifDisabled = true) do={
        :return "down"
    } else={
        :return "up"
    }
}

# Функция получения скорости интерфейса
:local getIfRate do={
    :global IFACE
    :global TYPES
    :local ifRate
    :local rateLen
    :local rateSuffix
    :local resultSpeed
    :local resultType
    /interface ethernet monitor $IFACE once do={
        :set $ifRate $rate
    }
    # Тип скорости определяем по суффиксу возвращенной строки
    # Он может быть либо Mbps либо Gbps соответственно
    # В качества суффикса используются последние 4 символа
    :set $rateLen [:len $ifRate]
    :set $rateSuffix [:pick $ifRate ($rateLen-4) $rateLen]
    :if ($rateSuffix in $TYPES) do={
        :set $resultSpeed [:pick $ifRate 0 ($rateLen-4)]
        :if ($rateSuffix = "Mbps") do={
            :set $resultType "M"
        }
        :if ($rateSuffix = "Gbps") do={
            :set $resultType "G"
        }
        # Возвращается массив из значения и типа скорости
        # Допустип массив {100; "M"} означает 100Mbps
        :return [:toarray $resultSpeed . ", " . $resultType]
    }
}


###################################################
## Основной код
###################################################

:log info "The LSR script execution is started"
:if ([$getIfState] = "up") do={
    :log info "The interface is in UP state"
    # Перезагружаем только, если значения скорости и типа
    # соответствуют заданным в разделе инициализации
    :if ([:pick $getIfRate 0] = $LOWSPEED) && ([:pick $getIfRate 1] = $SPEEDTYPE) do={
        :log info "The interface speed is low"
        :log info "The device must be rebooted"
        /system reboot
    } else={
        :log info "The interface speed is ok"
    }
} else={
    :log info "The interface is in DOWN state"
}
:log info "The LSR script execution is finished"
