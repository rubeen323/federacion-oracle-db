# Colocar aqui el certificado CA raiz del Active Directory en formato PEM.
# Nombre esperado: ad-ca.pem
#
# Para exportar la CA desde el DC (Windows Server 2016):
#   1. Abrir "Certification Authority" (certsrv.msc)
#   2. Click derecho en la CA raiz > Properties > View Certificate
#   3. Pestaña "Details" > "Copy to File..."
#   4. Seleccionar "Base-64 encoded X.509 (.CER)"
#   5. Guardar como ad-ca.pem
