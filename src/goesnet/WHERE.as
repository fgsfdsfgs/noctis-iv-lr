const string c_starmapPath = "data/STARMAP.BIN";

const string c_divider = "&&&&&&&&&&&&&&&&&&&&&";
const double c_removed = bytesToDouble("Removed:");

string rstrip(const string &in str) {
    int last = str.findLastNotOf(" \n\r\t\0");
    if (last >= 0)
        return str.substr(0, last+1);
    else
        return "";
}

int findobj(file & f, const string &in search, double &out found_id, string &out found_name) {
    const uint namelen = search.length();
    array<string> possible;

    f.setPos(4);

    while (!f.isEndOfFile()) {
        const double tmpid = f.readDouble();
        const string tmpname = f.readString(24);
        if (f.isEndOfFile()) break;

        // this originally read the IDs into doubles and compared with memcmp
        if (tmpid != c_removed) {
            // check for partial match
            if (tmpname.substr(0, namelen) == search) {
                found_id = tmpid;
                found_name = rstrip(tmpname.substr(0, 21));
                // check for exact match and return if found
                if (found_name == search) {
                    if (tmpname[21] == 'P') {
                        // what absolute madman came up with this
                        found_id -= (tmpname[22] - '0') * 10;
                        found_id -= (tmpname[23] - '0');
                        return 2;
                    } else {
                        return 1;
                    }
                }
                // store possible match in array for later
                possible.insertLast(found_name);
            }
        }
    }

    if (possible.length() > 0) {
        println("AMBIGUOUS SEARCH KEY:");
        println("PLEASE EXPAND NAME...");
        println(c_divider);
        println("POSSIBLE RESULTS ARE:");
        println(c_divider);
        for (uint i = 0; i < possible.length(); ++i)
            println(possible[i]);
        println(c_divider);
    } else {
        println("OBJECT NOT FOUND");
    }

    return 0;
}

void main(const string args) {
    if (args == "") {
        println("________USAGE________");
        println("WHERE PLANETNAME");
        println("^^^^^^^^^^^^^^^^^^^^^");
        println("PLEASE RUN AGAIN,");
        println("SPECIFYING PARAMETERS");
        return;
    }

    if (args.length() > 20) {
        println("INVALID PLANET NAME");
        return;
    }

    file fs;
    if (fs.open(c_starmapPath, "r") < 0) {
        println("STARMAP NOT AVAILABLE");
        return;
    }

    string found_name;
    double found_id;
    const int query = findobj(fs, args, found_id, found_name);

    if (query == 1) {
        println("THIS OBJECT IS A STAR");
        println("AND ITS POSITION CAN");
        println("BE DETERMINED USING");
        println("THE 'PAR' MODULE.");
    } else if (query == 2) {
        fs.setPos(4);

        while (!fs.isEndOfFile()) {
            const double tmpid = fs.readDouble();
            string tmpname = fs.readString(24);
            if (fs.isEndOfFile()) break;

            if (tmpid != c_removed && idEqual(tmpid, found_id)) {
                println(found_name);
                println("IS PART OF THE");
                tmpname.resize(20);
                println(tmpname);
                println("SYSTEM");
                fs.close();
                return;
            }
        }

        println("UNABLE  TO  DETERMINE");
        println("THIS PLANET'S  PARENT");
        println("STAR;  PROBABLY, THAT");
        println("STAR ISN'T CATALOGUED");
    }

    fs.close();
}