#!/bin/bash
IDProducto=4
if [ $# -ge 2 ]; then   # Se encarga de comprobar el numero de parametros, si es 2 o igual a dos o si no lo es
	while [[ $# -gt 0 ]]; do  # Es un bucle while que se encarga de estar ejecutando siempre que haya algun parametro de entrada
    OPCION=$1
	ARG1=$2
        case $OPCION in
        -c)
            if [ "$ARG1" = "lista" ]; then # si el argumento es lo mismo que lista,, que muestre la lista de carburantes
                curl -s https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/Listados/ProductosPetroliferos/ | jq -r '.[] | .NombreProducto'
            else # si no, daremos el valor del carburante que pusiste a la variable "NombreProducto" y luego sacaremos el id del mismo buscando con el jq, comparando el nombre del producto y sacando su correspondiente id
                NombreProducto="$ARG1"
                IDProducto=$(curl -s https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/Listados/ProductosPetroliferos/ | jq -r --arg NombreProducto "$NombreProducto" ' .[] | select(.NombreProducto==$NombreProducto) | .IDProducto ')
            fi
            shift # pasa de argumento, ponemos dos por que tiene que pasar tanto la opcion (-c o -l) y el dato que hayamos introducido (Nombre carburante o nombre municipio)
            shift
        ;;
        -l)
            for CIUDAD in "$@"; do   # en este bucle filtramos el contenido por municipio y carburante y lo volcamos a un fichero, utilizamos esto ">>" por que si utilizamos ">" nos machaca el contenido de antes, se repetira tantas veces como municipios hayamos puesto
                IDMunicipio=$(curl -s https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/Listados/Municipios/ | jq -r --arg CIUDAD "$CIUDAD" ' .[] | select(.Municipio==$CIUDAD) | .IDMunicipio ')
                curl -s https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/FiltroMunicipioProducto/{$IDMunicipio}/{$IDProducto} | jq -r  ' .ListaEESSPrecio[] | ."PrecioProducto" + "|" + ."Rótulo" + "|" + ."Dirección" + "|" + ."Localidad" ' >> carburantes.txt
                shift # pasa de argumento, ponemos dos por que tiene que pasar tanto la opcion (-c o -l) y el dato que hayamos introducido (Nombre carburante o nombre municipio)
                shift
            done
        ;;
        *)
            echo "Opción incorrecta" 
            shift
        ;;
        esac
done
else # se ejecutara si ponemos ./precarb.sh sin ningun parametro
	echo "Uso: precarb.sh [-c carburante] -l municipio1 [-l municipio2] [-l municipio3] ...
     precarb.sh -c lista"
fi
if [ -f carburantes.txt ]; then # Este if se encarga de mostrar el fichero que hemos estado rellenando con los datos de arriba, utilizamos el sort para ordenar los precios de menor a mayor, y utilizamos el column para que salga en forma de columna
cat carburantes.txt |sort -n| column -s "|" -t --table-columns Precio,Nombre,Dirección,Localidad
rm -r carburantes.txt
fi
