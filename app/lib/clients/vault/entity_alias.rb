module Clients
  class Vault
    module EntityAlias
      def put_entity_alias(entity_name, alias_name, auth_path)
        e = read_entity(entity_name)
        if e.nil?
          raise "no such entity #{entity_name}"
        end
        canonical_id = e.data[:id]
        auth_sym = "#{auth_path}/".to_sym
        accessor = client.logical.read("/sys/auth").data[auth_sym][:accessor]
        client.logical.write("identity/entity-alias",
                             name: alias_name,
                             canonical_id: canonical_id,
                             mount_accessor: accessor)
      end

      def read_entity_alias_id(entity_name, alias_name, auth_path)
        e = read_entity(entity_name)
        if e.nil?
          raise "no such entity #{entity_name}"
        end
        aliases = e.data[:aliases]
        a = find_alias(aliases, alias_name, auth_path)
        if a.nil?
          raise "no such alias #{alias_name}"
        end
        a[:id]
      end

      def read_entity_alias(entity_name, alias_name, auth_path)
        id = read_entity_alias_id(entity_name, alias_name, auth_path)
        client.logical.read("identity/entity-alias/id/#{id}")
      end

      def delete_entity_alias(entity_name, alias_name, auth_path)
        id = read_entity_alias_id(entity_name, alias_name, auth_path)
        client.logical.delete("identity/entity-alias/id/#{id}")
      end

      private
      def find_alias(aliases, name, auth_path)
        aliases.find { |a| a[:name] == name && a[:mount_path] == "auth/#{auth_path}/" }
      end
    end
  end
end
