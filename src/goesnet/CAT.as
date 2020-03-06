const string c_starmapPath = "data/STARMAP.BIN";
const string c_guidePath = "data/GUIDE.BIN";

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
                if (found_name == search)
                    return tmpname[21] == 'S' ? 1 : 2;
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
        println("CAT OBJECTNAME");
        println("CAT OBJECTNAME:X..Y");
        println("^^^^^^^^^^^^^^^^^^^^^");
        println("PLEASE RUN AGAIN,");
        println("SPECIFYING PARAMETERS");
        return;
    }

    println(" GOES GALACTIC GUIDE ");
    println(c_divider);

    string objname = "";
    int recstart = 1;
    int recend = 32767;
    int sep = args.findFirst(":");
    if (sep >= 0) {
        objname = args.substr(0, sep);
        string recstr = args.substr(sep + 1);
        sep = recstr.findFirst("..");
        if (sep >= 0) {
            recstart = parseInt(recstr.substr(0, sep));
            recend = parseInt(recstr.substr(sep + 2));
            if (recstart <= 0 || recend <= 0 || recstart > recend) {
                println("MALFORMED PARAMETERS");
                return;
            }
        }
    } else {
        objname = args;
    }

    if (objname == "" || objname.length() > 20) {
        println("INVALID OBJECT NAME");
        return;
    }

    file fs, fg;
    if (fs.open(c_starmapPath, "r") < 0) {
        println("STARMAP NOT AVAILABLE");
        return;
    }

    string found_name;
    double found_id;
    const int query = findobj(fs, objname, found_id, found_name);
    fs.close();

    if (query > 0) {
        if (query == 1)
            println("SUBJECT: STAR");
        else
            println("SUBJECT: PLANET");
        println(found_name);
        println(c_divider);

        if (fg.open(c_guidePath, "r") < 0) {
            println("DATABASE ERROR");
            println("(ERROR CODE 1003)");
        } else {
            int rec = 0;
            fg.setPos(4);

            while (!fg.isEndOfFile()) {
                const double recid = fg.readDouble();
                const string recmsg = rstrip(fg.readString(76));
                if (fg.isEndOfFile()) break;

                if (idEqual(recid, found_id)) {
                    ++rec;
                    // TODO: word wrap
                    if (rec >= recstart && rec <= recend) {
                        println("(" + rec + ")");
                        println(recmsg);
                    }
                }
            }

            fg.close();

            if (rec == 0) {
                println("THERE WERE NO RECORDS");
                println("IN THE GUIDE RELATING");
                println("SPECIFIED SUBJECT.");
            }
        }
    }
}
