// Tutorial: https://scotch.io/tutorials/authenticate-a-node-js-api-with-json-web-tokens

var express = require("express");
var jwt = require('jsonwebtoken'); // used to create, sign, and verify tokens
var config = require('../config'); // get our config file
var router = express.Router();
var mysql = require('mysql');
var db = require("../database/db")
var pool = mysql.createPool(db);

router
    .post('/api/authenticate', function(req, res) {
        // var result = "username: " + req.body.username + " password: " + req.body.password
        // res.send(result);
        pool.getConnection(function(err, connection) {
            var query = `
                SELECT * from user
                WHERE username = ?
                LIMIT 1
            `
            connection.query(query, req.body.username, function(err, rows) {
                // rows.length is used because not providing username or password returns an empty array from the query, which results in an undefined error i.e. username = rows[0].username cannot be set.
                if(rows.length > 0) {
                    // user is created because jwt.sign requires an object as the first parameter
                    // rows is accessed like an array ex. rows[0].username instead of rows.username, which returns undefined
                    var user = {
                        username: rows[0].username
                    }
                    // password is outside of user because it's a security flaw to have it in the token due to base64 encryption.
                    var password = rows[0].password_hash

                    if (err) throw err;

                    if (!user) {
                        // res.json({ success: false, message: 'Authentication failed. Wrong password.' });
                        res.status(401).send('Wrong username and password combination.');
                    } else if (user) {
                        // check if password matches
                        if (password != req.body.password) {
                            res.status(401).send('Wrong username and password combination.');
                        } else {
                            // if user is found and password is right, create a token
                            var token = jwt.sign(user, config.secret, {
                                expiresIn: 60*60*10  // expires in 10 hours
                            });

                            // return the information including token as JSON
                            res.json({
                                success: true,
                                token: token
                            });
                        }
                    }
                } else {
                    res.status(401).send('Please provide a valid username and password.');
                }
                connection.release();
            });
        });
    });

module.exports = router;
