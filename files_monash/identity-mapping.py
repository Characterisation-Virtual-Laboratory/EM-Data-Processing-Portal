import getopt
import json
import sys
import yaml


def main(args):
    opts, args = getopt.getopt(args, "as:c:")

    all_flag = False
    connector = None
    storage_gateway = None

    for o in opts:
        if o[0] == "-a":
            all_flag = True
        elif o[0] == "-c":
            connector = o[1]
        elif o[0] == "-s":
            storage_gateway = o[1]

    input_data = json.load(sys.stdin)
    # For testing purposes:
    # f = open('identity-input.json')
    # input_data = json.load(f)

    # For debugging purposes during development
    #json.dump(input_data, fp=sys.stdout)
    #sys.exit(0)

    if input_data.get("DATA_TYPE") != "identity_mapping_input#1.0.0":
        sys.exit("Invalid input DATA_TYPE")

    output_doc = {"DATA_TYPE": "identity_mapping_output#1.0.0", "result": []}

    mappings = read_mapfile(connector, storage_gateway)

    # For debugging purposes during development
    # json.dump(mappings, fp=sys.stdout)
    # sys.exit(0)

    for i in input_data.get("identities"):
        res = map_identity(i, mappings, all_flag)

        if res:
            output_doc["result"].extend(res)
            if not all_flag:
                break

    json.dump(output_doc, fp=sys.stdout)
    sys.exit(0)


def read_mapfile(connector, storage_gateway):
    # with open("monash_hpcid_usermap.yml") as f:
    with open("/opt/globus/gerp_users_usermap.yml") as f:
        mapfile = yaml.safe_load(f.read())

    mappings = mapfile
    return mappings


def map_identity(identity, mappings, all_flag):
    res = []

    for k, v in mappings.items():
        #email addresses are mixed case in yml, convert to lower, then compare
        if k.lower() == identity["email"].lower():
            res.append({"id": identity["id"], "output": v})
            break
        # if not all_flag:
        #     break
    return res


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
