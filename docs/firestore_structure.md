# Estructura Firestore de FIGUGOL

Este documento describe la estructura inicial recomendada para las colecciones de FIGUGOL. Los nombres de colecciones y campos se mantienen en inglés.

## `users/{uid}`

Perfil privado del usuario autenticado.

Campos principales:
- `uid`: ID de Firebase Authentication.
- `email`: email del usuario.
- `displayName`: nombre recibido desde Google.
- `photoUrl`: foto recibida desde Google.
- `exchangeName`: nombre visible para intercambios.
- `createdAt`: fecha de creación.
- `updatedAt`: última actualización.
- `locationConfirmed`: `true` si confirmó ubicación.
- `selectedExchangePoints`: lista de IDs de puntos elegidos.
- `location`: mapa con `latitude`, `longitude`, `confirmedAt`, `sector`, `nearbyRadiusKm`.

Subcolección:
- `users/{uid}/exchangePoints/{pointId}`: puntos seleccionados para intercambio presencial.

## `sticker_collections/{uid}/stickers/{stickerId}`

Colección personal de figuritas del usuario.

Campos:
- `userId`
- `stickerId`
- `quantity`
- `updatedAt`

## `tradeOffers/{offerId}`

Ofertas publicadas para intercambio.

Campos:
- `id`
- `ownerId`
- `ownerName`
- `ownerPhotoUrl`
- `stickersOffered`
- `missingStickers`
- `exchangePoints`
- `latitude`
- `longitude`
- `zoneHash`
- `status`: `active`, `reserved`, `completed`, `cancelled`.
- `createdAt`
- `updatedAt`

Lectura recomendada:
- Usuarios autenticados pueden leer ofertas `active`.
- El dueño puede crear y actualizar su oferta.
- Un usuario autenticado puede reservar una oferta activa mediante pago simulado, cambiando solo `status` a `reserved` y `updatedAt`.

## `tradeProposals/{proposalId}`

Propuestas creadas a partir de una oferta.

Campos:
- `id`
- `offerId`
- `fromUserId`
- `toUserId`
- `offeredStickers`
- `requestedStickers`
- `status`: `pending`, `accepted`, `rejected`, `completed`.
- `createdAt`

Acceso recomendado:
- Solo `fromUserId` y `toUserId` pueden leer la propuesta.

## `paymentSimulations/{paymentId}`

Pagos simulados de la tiendita. No contiene datos reales de pago.

Campos:
- `id`
- `userId`
- `offerId`
- `quantity`
- `unitPrice`
- `total`
- `currency`
- `status`: `simulated_success`, `simulated_failed`, `cancelled`.
- `createdAt`

La app usa esta colección para el flujo visual de pago simulado. No debe almacenar tarjetas, credenciales, claves ni datos de pago reales.
