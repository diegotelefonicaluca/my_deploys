#!/bin/bash

# Copia los contenidos de glue, desde el directorio "engineering" a "infrastructure/terraform"
JOBS_SOURCE_PATH=../../engineering/glue/scripts
JOBS_TARGET_PATH=././glue/jobs #./infrastructure/terraform/glue/jobs

LIBS_SOURCE_PATH=../../engineering/glue/lib
LIBS_TARGET_PATH=././glue/libs #./infrastructure/terraform/glue/libs

#Borramos el contenido del directorio ./infrastructure/terraform/glue/jobs
rm $JOBS_TARGET_PATH/*
#Borramos el contenido del directorio ./infrastructure/terraform/glue/libs
rm $LIBS_TARGET_PATH/*

# Copiamos las librerías y código fuente de los jobs de glue
cp -rf $JOBS_SOURCE_PATH/* $JOBS_TARGET_PATH
cp -rf $LIBS_SOURCE_PATH/* $LIBS_TARGET_PATH