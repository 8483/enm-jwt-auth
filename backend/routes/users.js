var express = require("express");
var router = express.Router();
var mysql = require('mysql');
var db = require("../database/db")
var pool = mysql.createPool(db);

// TARGER ADDRESS
// http://localhost:3000/api/users/1/clients/2/journals/3/transactions/4

router
    .get("/api/users", function(req, res){
        pool.getConnection(function(err, connection) {
            connection.query( 'SELECT * from user', function(err, rows) {
                if (!err){
                    console.log(rows);
                    res.send(rows);
                } else {
                    console.log('Error: ' + err);
                }
                connection.release();
            });
        });
    });

module.exports = router;
