provider "kubernetes" {}

resource "kubernetes_pod" "apache" {
  metadata {
    name = "apache-example"
    labels = {
      App = "apache"
    }
  }

  spec {
    container {
      image = "httpd:2.4"
      name  = "example-apache"

      port {
        container_port = 80
      }
    }
  }
}

resource "kubernetes_service" "apache" {
  metadata {
    name = "apache-example"
  }
  spec {
    selector = {
      App = kubernetes_pod.apache.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = kubernetes_service.apache.load_balancer_ingress[0].hostname
}
resource "kubernetes_namespace" "elasticsearch" {
  metadata {
    name = "kube-logging"
  }
}
resource "kubernetes_service" "elasticsearch" {
  metadata {
    name = "elasticsearch"
    namespace = "kube-logging"
    labels = {
      App = "elasticsearch"
    }
  }
  spec {
    selector = {
      App = "elasticsearch"
    }
    port {
      name = "rest"
      port = 9200
    }
    port {
      name = "inter-node"
      port = 9300
    }
  }
}

resource "kubernetes_stateful_set" "elasticsearch"{
  metadata {
      name = "es-cluster"
      namespace = "kube-logging"
  }
  spec {
    service_name = "elasticsearch"
    replicas = 3
    selector  {
    match_labels = { 
      App = "elasticsearch"
    }
    }
    template  {
      metadata  {
        labels = {
          App = "elasticsearch"
        }
      }
      spec {
      container {
          name = "elasticsearch"
          image = "docker.elastic.co/elasticsearch/elasticsearch:7.2.0"
          resources {
              limits {
                  cpu = "1000m"
              }
              requests {
                  cpu = "100m"
              }

          }
          port {
              container_port = 9200
              name = "rest"
              protocol = "TCP"
          }
          port {
              container_port = 9300
              name = "inter-node"
              protocol = "TCP"
          }
          volume_mount {
              name = "data"
              mount_path= "/usr/share/elasticsearch/data"
          }
          env {
              name = "cluster.name"
              value = "k8s-logs"
          }
          env {
              name = "node.name"
              value_from  {
                  field_ref  {
                      field_path = "metadata.name"
                  }
              }
          }
          env {
              name = "discovery.seed_hosts"
              value = "es-cluster-0.elasticsearch,es-cluster-1.elasticsearch,es-cluster-2.elasticsearch"
          }
          env {
              name = "cluster.initial_master_nodes"
              value = "es-cluster-0,es-cluster-1,es-cluster-2"
          }
          env {
              name = "ES_JAVA_OPTS"
              value = "-Xms512m -Xmx512m"
          }

      } 
    init_container {
          name              = "fix-permissions"
          image             = "busybox"
          command           = ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
          security_context {
              privileged = true
          }
          volume_mount {
            name       = "data"
            mount_path = "/usr/share/elasticsearch/data"
          }
          
    }
    init_container {
          name              = "increase-vm-max-map"
          image             = "busybox"
          command           = ["sysctl", "-w", "vm.max_map_count=262144"]
          security_context {
              privileged = true
          }
    }
    init_container {
          name              = "increase-fd-ulimit"
          image             = "busybox"
          command           = ["sh", "-c", "ulimit -n 65536"]
          security_context {
              privileged = true
          }
    }
    
    
    }
    }
    volume_claim_template {
      metadata {
        name = "data"
        labels = {
            App = "elasticsearch"
        }
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "do-block-storage"

        resources {
          requests = {
            storage = "5Gi"
          }
        }
      }
    
    }
    
  }

}