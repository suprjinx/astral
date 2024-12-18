module Clients
  class Vault
    module KeyValue
      extend Policy

      def kv_read(identity, path)
        kv_metadata = KvMetadata.find_by(path: path)
        verify_policy(identity, producer_policy_path(path), kv_metadata&.read_groups, consumer_policy_path(path))
        client.kv(kv_mount).read(path)
      end

      def kv_write(identity, read_groups, path, data)
        # only producer can replace existing secret
        if client.kv(kv_mount).read(path)
          verify_policy(identity, producer_policy_path(path))
        end

        create_kv_policies(path)
        assign_entity_policy(identity, producer_policy_path(path))
        assign_groups_policy(read_groups, consumer_policy_path(path))
        secret = client.logical.write("#{kv_mount}/data/#{path}", data: data)
        KvMetadata.find_or_create_by(path: path).update(owner: identity.sub, read_groups: read_groups)
        secret
      end

      def kv_delete(identity, path)
        unless client.kv(kv_mount).read(path)
          return
        end
        verify_policy(identity, producer_policy_path(path))
        kv_metadata = KvMetadata.find_by(path: path)
        client.logical.delete("#{kv_mount}/data/#{path}")
        remove_entity_policy(identity, producer_policy_path(path))
        remove_groups_policy((kv_metadata&.read_groups || []), consumer_policy_path(path))
        kv_metadata.destroy! if kv_metadata
      end

      def configure_kv
        unless client.sys.mounts.key?(kv_mount.to_sym)
          enable_engine(kv_mount, kv_engine_type)
        end
      end

      private

      def kv_mount
        "kv_astral"
      end

      def kv_engine_type
        "kv-v2"
      end

      def create_kv_policies(path)
        client.sys.put_policy(producer_policy_path(path), kv_producer_policy(path))
        client.sys.put_policy(consumer_policy_path(path), kv_consumer_policy(path))
      end

      def producer_policy_path(path)
        "#{kv_mount}_policy/#{path}/producer"
      end

      def consumer_policy_path(path)
        "#{kv_mount}_policy/#{path}/consumer"
      end

      def kv_producer_policy(path)
        policy = <<-EOH
               path "#{path}" {
                 capabilities = ["create", "read", "update", "delete"]
               }
        EOH
      end

      def kv_consumer_policy(path)
        policy = <<-EOH
               path "#{path}" {
                 capabilities = ["read"]
               }
        EOH
      end
    end
  end
end
