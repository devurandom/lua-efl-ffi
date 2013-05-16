#!/bin/bash

CPP=cpp

headers="$@" ; shift
[[ "${headers}" ]] || exit 1

for h in ${headers} ; do
	dir=$(dirname "${h}")
	lib=$(basename "${dir%-1}")
	inc=$(pkg-config --cflags-only-I "${lib}")

	out=pre/"${lib}"/$(basename "${h}" .h).E

	mkdir -p pre/"${lib}"

	egrep -v '^#\s*include' "${h}" \
		| ${CPP} \
		-std=c99 -undef -P \
		-D'EAPI'= \
		-D'EINA_PURE'= \
		-D'EINA_WARN_UNUSED_RESULT'= \
		-D'EINA_ARG_NONNULL(...)'= \
		${inc} \
		-o "${out}"

	sed -i "${out}" \
		-e 's/Eina_Rbtree_Color color : 1/unsigned int color : 1/'
done
