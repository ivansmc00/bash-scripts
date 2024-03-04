#! /bin/bash

##### Script realizado por Manuel Iván San Martín Castillo #####

##### Variable globales del script #####
RED='\033[0;31m';
GREEN='\033[0;32m';
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

##### Función de interrupción del programa que borra la carpeta de destino #####
interrupter(){
        rm -rf $OUTPUT_DIR 2>/dev/null
        rm -f /tmp/$TAR_NAME 2>/dev/null
        exit 1
}

##### Función de carga de espera #####
loading(){
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
echo -ne "\r$TXT - ${GREEN}${BOLD}DONE\n${NC}";
}

##### Control de introducción del fichero/dispositivo de origen #####
while true; do
        echo -e "${BOLD}"
        read -p "Introduce fichero/dispositivo de origen: " INPUT
        [ ! -e "$INPUT" ] && echo -e "${RED}${BOLD}ERROR: El fichero $INPUT no existe${NC}" || break;
done;

##### Control de introducción del directorio de destino #####
while true; do
        echo "";
        read -p "Introduce directorio de destino: " OUTPUT
        echo -e "${NC}"
        [ ! -d "$OUTPUT" ] && echo -e "${RED}${BOLD}ERROR: $OUTPUT no es un directorio válido${NC}" || break;
done;

##### Seleccionador del HASH #####
echo -e "${BOLD}===== Selecciona un HASH =====";
PS3="Introduce un número: ";
select OPT in " MD5" " SHA1" " SHA256" " SHA512"; do
        case $REPLY in
                1)
                        HASH="md5sum";
                        break;
                ;;
                2)
                        HASH="sha1sum";
                        break;
                ;;
                3)
                        HASH="sha256sum";
                        break;
                ;;
                4)
                        HASH="sha512sum";
                        break;
                ;;
        esac;
done;

##### Control de compresión del directorio de destino #####
while true; do
        echo -e "${BOLD}"
        read -p "¿Desea comprimir los ficheros?(Y/N) " COMPRESSION
        case $COMPRESSION in
                y|Y)
                        COMPRESSION=True;
                        break;
                ;;
                n|N)
                        COMPRESSION=False;
                        break;
                ;;
        esac;
done;

mkdir "$OUTPUT/$(basename $INPUT | cut -d '.' -f1)_adquisition" 2>/dev/null
OUTPUT_DIR="$OUTPUT/$(basename $INPUT | cut -d '.' -f1)_adquisition"
TAR_NAME="$(basename $INPUT | cut -d '.' -f1)-image.tar.gz"

trap interrupter SIGINT;

##### Obtención de la imagen #####
echo "";
TXT="${BOLD}Copiando ${BLUE}${BOLD}$INPUT${NC}${BOLD} en el directorio ${BLUE}${BOLD}$(readlink -f $OUTPUT_DIR)${NC}";
dd if="$INPUT" of="$OUTPUT_DIR/$(basename $INPUT | cut -d '.' -f1)-image.img" 2>/dev/null &
loading

##### Obtención del HASH #####
TXT="${BOLD}Obteniendo el hash de ${BLUE}${BOLD}$INPUT${NC}";
$HASH $INPUT > "$OUTPUT_DIR/$(basename $INPUT | cut -d'.' -f1)-hash-${HASH}.txt" &
loading

##### Obtención del directorio comprimido #####
if [[ "$COMPRESSION" == "True" ]]; then
        TXT="${BOLD}Comprimiendo contenido del directorio ${BLUE}${BOLD}$(readlink -f $OUTPUT_DIR)${NC}";
        tar -czf "/tmp/$TAR_NAME" $OUTPUT_DIR 2>/dev/null &
        loading

        TXT="${BOLD}Finalizando la adquisición${NC}"
        cp /tmp/$TAR_NAME $OUTPUT_DIR &
        loading
        rm -f /tmp/$TAR_NAME
fi;

echo -e "\n${GREEN}${BOLD}Adquisición de ${BLUE}${BOLD}$INPUT${GREEN}${BOLD} realizada con éxito${NC}${BOLD}"
echo -e "\n${GREEN}${BOLD}Contenido almacenado el el directorio ${YELLOW}${BOLD}=> ${BLUE}${BOLD}$(readlink -f $OUTPUT_DIR)"
exit 0
