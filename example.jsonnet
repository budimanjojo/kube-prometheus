local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/addons/strip-limits.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/external-metrics.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring-system',
      },
      kubePrometheus+: {
        platform: 'kubeadm'
      },
      prometheus+: {
        replicas: 1,
        namespaces+: ['ingress-system', 'flux-system'],
      },
      alertmanager+: {
        config: |||
          global:
            resolve_timeout: 5m
          inhibit_rules:
          - equal:
            - namespace
            - alertname
            source_match:
              severity: critical
            target_match_re:
              severity: warning|info
          - equal:
            - namespace
            - alertname
            source_match:
              severity: warning
            target_match_re:
              severity: info
          receivers:
          - name: Default
            webhook_configs:
            - url: "http://alertmanager-notifier-svc.monitoring-system.svc.cluster.local:8899/alert"
          - name: Watchdog
          - name: Critical
            webhook_configs:
            - url: "http://alertmanager-notifier-svc.monitoring-system.svc.cluster.local:8899/alert"
          route:
            group_by:
            - namespace
            group_interval: 5m
            group_wait: 30s
            receiver: Default
            repeat_interval: 12h
            routes:
            - match:
                alertname: Watchdog
              receiver: Watchdog
            - match:
                severity: critical
              receiver: Critical
      |||,
        replicas: 1,
      },
    },
  };

{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'deploy/prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'deploy/prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'deploy/kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['deploy/alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['deploy/blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['deploy/kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['deploy/kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['deploy/node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['deploy/prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['deploy/prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) }
