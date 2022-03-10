import QtQuick 2.2
import QtQuick.LocalStorage 2.0 as Sql

Item {

    QtObject {
        id: internal
        // reference to the database object
        property var _db
    }

    property variant record

    function initDatabase() {
        // initialize the database object
        console.log('initDatabase()')
        internal._db = Sql.LocalStorage.openDatabaseSync("OldiesRadio", "1.0", "OldiesRadio settings SQL database", 1000000);
        internal._db.transaction( function(tx) {
            // Create the database if it doesn't already exist
            console.log("Create the database if it doesn't already exist")
            tx.executeSql('CREATE TABLE IF NOT EXISTS settings(keyname TEXT UNIQUE, value TEXT, textName TEXT)')
            tx.executeSql('CREATE TABLE IF NOT EXISTS favorites(keyname TEXT UNIQUE, title TEXT, description TEXT, stream TEXT)')

            var columnExists = tx.executeSql('PRAGMA table_info(favorites)')

            if(columnExists.rows.length === 4) {
                    //ALTER TABLE {tableName} ADD COLUMN COLNew {type}
                    tx.executeSql('ALTER TABLE favorites ADD COLUMN radioLogo TEXT')
            }
        })
    }

    function storeData(keyname, value, textName) {
        // stores data to _db
        console.log('storeData()', keyname, value, textName)
        if(!internal._db) { return }
        internal._db.transaction( function(tx) {
            var result = tx.executeSql('INSERT OR REPLACE INTO settings VALUES (?,?,?);', [keyname,value,textName])
            if(result.rowsAffected === 1) {// use update
                console.log('record exists, update it')
            }
        })
    }

    function getValue(keyname) {
        console.log('getValue()', keyname)
        var res
        if(!internal._db) { return }
        internal._db.transaction( function(tx) {
            var result = tx.executeSql('SELECT value from settings WHERE keyname=?', [keyname])
            if(result.rows.length === 1) {// use update
                res = result.rows.item(0).value
            }
        })
        return res
    }

    function getName(keyname) {
        console.log('getName()', keyname)
        var res
        if(!internal._db) { return }
        internal._db.transaction( function(tx) {
            var result = tx.executeSql('SELECT textName from settings WHERE keyname=?', [keyname])
            if(result.rows.length === 1) {// use update
                res = result.rows.item(0).textName
                console.log("tx result", res)
            }
        })
        return res
    }

    function addFavorite(title, description, stream, radioLogo) {
        var res = false
        // stores favorite to _db
        console.log('addFavorite()', title, description, stream, radioLogo)
        if(!internal._db) { return }
        internal._db.transaction( function(tx) {
            var result = tx.executeSql('INSERT OR REPLACE INTO favorites VALUES (?,?,?,?,?);', [title, title, description, stream, radioLogo])
            if(result.rowsAffected === 1) {// use update
                console.log('record exists, update it', JSON.stringify(result))
                res = true
            }
        })
        return res
    }

    function getFavorites() {
        var res = []
        if(!internal._db) { return }
        console.log("get favs")
        internal._db.transaction( function(tx) {
            var result = tx.executeSql('select * from favorites')
            console.log("get favs", JSON.stringify(result))
            for (var i=0; i < result.rows.length; i++) {
                console.log('record exists', JSON.stringify(result.rows.item(i)))
                res.push(result.rows.item(i))
            }
        })
        return res
    }

    function deleteFavorite(id) {
        var res = false
        if(!internal._db) { return }
        console.log("id", id)
        internal._db.transaction( function(tx) {
            var result = tx.executeSql('DELETE from favorites WHERE keyname=?', [id])
            console.log("Delete data from the trackData table result\n", JSON.stringify(result))
            if(result.rowsAffected === 1) {// use update
                console.log('record exists, delete it', JSON.stringify(result))
                res = true
            }
        })
        return res
    }
}
