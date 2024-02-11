# Aplicación de ejemplo en Angular: Tour Of Heroes

En esta versión de la API para el frontend del [tutorial de AngularJS](https://angular.io/tutorial), se modifica el método ***putHero*** para que, cuando se modifica el nombre del alter ego se añada en una cola de mensaje la tarea de modificar el nombre de la imagen de este con el nombre actualizado:

```
// PUT: api/Hero/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{id}")]
        public async Task<IActionResult> PutHero(int id, Hero hero)
        {
            if (id != hero.Id)
            {
                return BadRequest();
            }
            var oldHero = await _context.Heroes.FindAsync(id);
            _context.Entry(oldHero).State = EntityState.Detached;


            _context.Entry(hero).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();

                /*********** Background processs (We have to rename the image) *************/
                if (hero.AlterEgo != oldHero.AlterEgo)
                {
                    // Get the connection string from app settings
                    string connectionString = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONNECTION_STRING");

                    // Instantiate a QueueClient which will be used to create and manipulate the queue
                    var queueClient = new QueueClient(connectionString, "alteregos");

                    // Create a queue
                    await queueClient.CreateIfNotExistsAsync();

                    // Create a dynamic object to hold the message
                    var message = new
                    {
                        oldName = oldHero.AlterEgo,
                        newName = hero.AlterEgo
                    };

                    // Send the message
                    await queueClient.SendMessageAsync(JsonSerializer.Serialize(message).ToString());

                }
                /*********** End Background processs *************/
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!HeroExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

```

En este ejemplo se utiliza Azurite como emulador de Azure Storage para el desarrollo local. Puedes ejecutar Azurite dentro de un contenedor de Docker con el siguiente comando:

```bash
docker run --name azurite \
-d \
-p 10000:10000 \
-p 10001:10001 \
-p 10002:10002 \
mcr.microsoft.com/azure-storage/azurite
```

El puerto 10000 es el puerto de Blob, el puerto 10001 es el puerto de Queue y el puerto 10002 es el puerto de Table.

Para que tu aplicación sea consciente de Azurite debes añadir la cadena de conexión en el archivo ***appsettings.Development.json*** con el siguiente contenido:

```json
{
  "ConnectionStrings": {
    "AzureStorage": "UseDevelopmentStorage=true"
  }
}
```

