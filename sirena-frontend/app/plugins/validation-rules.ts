export default defineNuxtPlugin(() => {
    const Rules = {
        // Regla: Campo Requerido (excluye null, undefined, cadena vacía)
        obligatoria(msg?: string) {
            return (v: any) => (v !== null && v !== undefined && v !== '') || msg || 'Campo requerido'
        },

        // Regla: Solo números y letras (ideal para códigos)
        soloNumerosYLetras(msg?: string) {
            return (v: string) =>!v || /^[A-Za-z0-9-]*$/.test(v) || msg || 'Solamente se permiten números y letras'
        },

        // Regla: Solo letras (incluye tildes y ñ)
        soloLetrasEsp(msg?: string) {
            return (v: string) => !v || /^[ A-Za-zñÑÁáÉéÍíóÓúÚüÜ]*$/.test(v) || msg || 'Solamente se permiten letras'
        },

        // Regla: Longitud máxima
        longitudMaxima(val: number, msg?: string) {
            return (v: string) =>!v || v.length <= val || msg || `Máximo ${val} caracteres permitidos`
        },

        // Regla: Formato de correo
        formatoCorreo(msg?: string) {
            return (v: string) => {
                if (!v) return true;
                const regex = /^[a-zA-Z0-9._%+-]+@(?!\.)(?!.*\.\.)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
                if (v.includes(' ')) {
                    return msg ?? 'El correo no debe contener espacios';
                }

                return regex.test(v) ? true : (msg ?? 'Formato de correo inválido');
            };
        },

        // Valida que no existan acentos extranjeros, símbolos prohibidos o caracteres trampa.
        textoSeguro(msg?: string) {
            return (v: string) => {
                if (!v) return true;

                const latinExtRegExp = /[ÀàÈèÌìÒòÙùÂâÊêÎîÔôÛûÇçÄäËëÏïÖö]/;
                const symbolsRegExp = /[¿¡€$&@#|«»“”"']/;
                const trapCharsRegExp = /[\u00A0\u2013\u2014]/;

                if (latinExtRegExp.test(v)) {
                    return msg || 'Contiene caracteres de otros idiomas no permitidos (acentos graves, cedillas, etc.)';
                }
                if (symbolsRegExp.test(v)) {
                    return msg || 'Contiene símbolos especiales o comillas no permitidas.';
                }
                if (trapCharsRegExp.test(v)) {
                    return msg || 'Contiene espacios o guiones con formato inválido.';
                }

                return true;
            };
        },

        // Valida que el texto esté entre un mínimo y un máximo.
        longitudRango(min: number, max: number, msg?: string) {
            return (v: string) => {
                if (!v) return true;
                const val = v.toString().trim();
                if (val.length < min || val.length > max) {
                    return msg || `Debe tener entre ${min} y ${max} caracteres.`;
                }
                return true;
            };
        },

        /**
         * Regla: Password Fuerte
         * Requisitos: Mínimo 6 caracteres, 1 Mayúscula, 1 Minúscula, 1 Número y 1 Carácter Especial.
         */
        passwordFuerte(msg?: string) {
            return (v: string) => {
                if (!v) return true;
                const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$/;
                return regex.test(v) || msg || 'La contraseña debe tener al menos 6 caracteres, incluir una mayúscula, una minúscula, un número y un carácter especial.';
            };
        },

        confirmarPassword(passwordOriginal: string, msg?: string) {
            return (v: string) => v === passwordOriginal || msg || 'Las contraseñas no coinciden';
        },

        // Regla: Solo números positivos y decimales (Dinero)
        soloDinero(msg?: string) {
            return (v: any) => {
                if (v === null || v === undefined || v === '') return true;
                // Permite números enteros o decimales con punto o coma
                const regex = /^\d+([.,]\d{1,2})?$/;
                return regex.test(v.toString()) || msg || 'Monto inválido (máximo 2 decimales)';
            };
        },

        // Regla: Monto mayor a cero (Para evitar registros en 0)
        dineroMayorACero(msg?: string) {
            return (v: any) => {
                if (!v) return true;
                const num = parseFloat(v.toString().replace(',', '.'));
                return num > 0 || msg || 'El monto debe ser mayor a 0';
            };
        },

        numeroMaximo(max: number, msg?: string) {
            return (v: any) => {
                if (v === null || v === undefined || v === '') return true;
                const num = parseFloat(v.toString().replace(',', '.'));
                return num <= max || msg || `El valor no puede ser mayor a ${max}`;
            };
        },
        
        // Regla: Solo números enteros (útil para Stock o Cantidades)
        soloEnteros(msg?: string) {
            return (v: any) => {
                if (v === null || v === undefined || v === '') return true;
                return /^\d+$/.test(v.toString()) || msg || 'Solo se permiten números enteros';
            };
        },

        // Regla: Stock mínimo (para que no te permitan vender sin existencias)
        stockMinimo(min: number = 1, msg?: string) {
            return (v: any) => {
                if (!v) return true;
                return parseInt(v) >= min || msg || `La cantidad mínima debe ser ${min}`;
            };
        },

        // Regla: Selección obligatoria para objetos o arrays (PrimeVue Select)
        seleccionObligatoria(msg?: string) {
            return (v: any) => {
                if (Array.isArray(v)) return v.length > 0 || msg || 'Debe seleccionar al menos un elemento';
                return (v !== null && v !== undefined && Object.keys(v).length > 0) || msg || 'Debe seleccionar una opción';
            };
        },

        // Regla: Fecha no sea futura (para fechas de nacimiento o registros históricos)
        fechaNoFutura(msg?: string) {
            return (v: any) => {
                if (!v) return true;
                const fecha = new Date(v);
                const hoy = new Date();
                return fecha <= hoy || msg || 'La fecha no puede ser mayor a la de hoy';
            };
        },
    }
    
    return {
        provide: {
            rules: Rules,
            $rules: Rules,
        },
    }
})