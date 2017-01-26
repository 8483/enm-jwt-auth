var hidden = require("../hidden"); // Delete this line.

module.exports = {
    host     : 'localhost',
    user     : 'root',
    password : hidden.databasePassword, // Put your own database password.
    database : 'jwt_login'
}
