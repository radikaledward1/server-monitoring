#!/bin/bash

# Server Health Checker
# Description: Retrives the information related witn the server health status generated by the health-collector.sh script.
# Version: 1.0.0
# Author: Oscar Gonzalez Gamboa
# Date: 2023-11-03
# License: GPL 2+

# Verificar si "expect" está instalado
if [ ! -x "$(command -v expect)" ]; then
    echo "Error: El comando 'expect' no está instalado en este sistema."
    exit 1
fi

# Variables para la conexión SSH y los servidores remotos
servers=("146.190.119.248")
user="root"
password="xE5008atXasE21a"

# Variables para el script remoto
remote_collector_file="/health-collector.sh"

# Variable para el archivo local donde se guardarán los resultados
local_report_file="report.txt"

# Crear el archivo local (vacío) antes de la ejecución
touch "$local_report_file"

# Mostrar un mensaje informativo
echo "Starting health check..."

# Bucle para conectar con múltiples servidores remotos

# for ((i = 0; i < ${#servers[@]}; i++)); do
#     remote_server="${servers[$i]}"
    
#     echo "Retrieving status from $remote_server..."
#     # Comando SSH para conectarse al servidor remoto y ejecutar el script remoto
#     expect -c "
#     spawn ssh \"$user@$remote_server\" \"$remote_collector_file\"
#     expect \"password:\"
#     send \"$password\r\"
#     expect eof
#     " >> "$local_report_file" 2>&1  # Redirigir la salida al archivo local (append)

#     echo "Closing connection with $remote_server..."
#     echo "Bye Bye!"
# done

for ((i = 0; i < ${#servers[@]}; i++)); do
    remote_server="${servers[$i]}"
    
    echo "Retrieving status from $remote_server ..."

    # Comando SSH para conectarse al servidor remoto y ejecutar el script remoto
    expect -c "
    spawn ssh \"$user@$remote_server\" \"$remote_collector_file\"
    expect {
        \"password:\" {
            send \"$password\r\"
            exp_continue
        }
        -re {Error|Failed|No such file|Permission denied} {
            send_error \"Error: $expect_out(0,string)\"
            exit 1
        }
        eof
    }
    " >> "$local_report_file" 2>&1  # Redirigir la salida al archivo local (append)
    
    if [ $? -ne 0 ]; then
        echo "Error detected during the execution of the remote script on $remote_server."
        # Puedes agregar lógica adicional para manejar errores aquí, si es necesario.
    else
        echo "Status retrieved successfully from $remote_server."
    fi
    
    echo "Closing connection with $remote_server ..."
    echo "Bye Bye!"
done

# Mostrar un mensaje de confirmación
echo "Report file generated."
echo "Done!"
