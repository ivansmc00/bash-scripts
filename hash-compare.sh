#! /bin/bash

##### Variable globales del script #####
RED='\033[0;31m';
GREEN='\033[0;32m';
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'
HASH_DEV="";
HASH_IMG="";

##### Funcion de error #####
error(){
cat << EOF

USO: ./hash-compare.sh dispositivo_origen ruta_imagen
Este script compara el hash del "dispositivo_origen" con el hash de "ruta_imagen", ambos con direccionamiento absoluto.

EOF
}

##### Funcion de interrupción del programa que borra el archivo temporal #####
interrupter(){
        rm $TMP_FILE;
        exit 1
}

decorate(){
        echo "";
        local DECO="";
        for i in {1..65}; do
                DECO+='='
        done;
        echo -e "${BOLD}$DECO${NC}";
}

##### Función para calcular el hash de los elementos #####
hashing(){
        local PP=$1
        local HASH=$2
        echo "";
        TXT="${BOLD}Obteniendo hash de ${BLUE}${BOLD}$PP${NC}";
        TMP_FILE=$(mktemp);
        sha256sum "$PP" > "$TMP_FILE" &

        while kill -0 $! 2>/dev/null; do
                for i in {1..3};do
                        TXT+=".";
                        echo -ne "\r$TXT"
                        sleep 0.2
                done;

                for i in {1..3};do
                        TXT="${TXT%?}";
                        echo -ne "\r$TXT"
                        sleep 0.2
                done;
        done;

        if [[ "$HASH" == "True" ]]; then
                read HASH_DEV < "$TMP_FILE";
                HASH_DEV=$(echo $HASH_DEV | cut -d " " -f1);
                echo -e "\n$HASH_DEV";
        else
                read HASH_IMG < "$TMP_FILE";
                HASH_IMG=$(echo $HASH_IMG | cut -d " " -f1);
                echo -e "\n$HASH_IMG";
        fi;
        rm "$TMP_FILE";
        echo "";
}

##### Se comprueba que se introducen 2 PP #####
([ $# -ne 2 ]) && error && exit;

##### Se comprueba que el fichero especificado existe y que el primer caracter empieza por / para asegurar que es direccionamiento absoluto #####
if ! [ -f $1 ] || ! [ "$(echo ${1:0:1})" == "/" ]; then
        if ! [ -f $2 ] || ! [ "$(echo ${2:0:1})" == "/" ]; then
                error;
                echo -e "${RED}${BOLD}ERROR: Los valores introducidos no son archivos válidos";
                exit;
        fi;
fi;

trap interrupter SIGINT;
decorate;
hashing "$1" True;
hashing "$2" False;

##### Se comprueba si los HASHES son iguales o diferentes
if [[ "$HASH_DEV" == "$HASH_IMG" ]]; then
        echo -e "${GREEN}${BOLD}Los HASHES son iguales${NC}";
        decorate;
        exit 0;
else
        echo -e "${RED}${BOLD}Los HASHES son diferentes${NC}";
        decorate;
        exit 0;
fi;
