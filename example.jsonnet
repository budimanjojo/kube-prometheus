// disable CPUThrottlingHigh alert
local prometheus_allow_ingress = {
  prometheus+: {
    networkPolicy+: {
      spec+: {
        ingress+: [{
          from: [{
            podSelector: {
              matchLabels: {
                'app.kubernetes.io/name': 'traefik',
              },
            },
            namespaceSelector: {
              matchLabels: {
                'kubernetes.io/metadata.name': 'ingress-system',
              },
            },
          }],
        }],
      },
    },
  },
};

local disable_cputhrottlinghigh_alert = {
  kubernetesControlPlane+: {
    prometheusRule+: {
      spec+: {
        groups: std.map(
          function(group)
            if group.name == 'kubernetes-resources' then
              group {
                rules: std.filter(
                  function(rule)
                    rule.alert != 'CPUThrottlingHigh',
                  group.rules
                ),
              }
            else
              group,
          super.groups
        ),
      },
    },
  },
};

local disable_kubeproxy_alert = {
  kubernetesControlPlane+: {
    prometheusRule+: {
      spec+: {
        groups: std.map(
          function(group)
            if group.name == 'kubernetes-system-kube-proxy' then
              group {
                rules: std.filter(
                  function(rule)
                    rule.alert != 'KubeProxyDown',
                  group.rules
                ),
              }
            else
              group,
          super.groups
        ),
      },
    },
  },
};

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/external-metrics.libsonnet') +
  disable_kubeproxy_alert + disable_cputhrottlinghigh_alert + prometheus_allow_ingress +
  {
    values+:: {
      common+: {
        namespace: 'monitoring-system',
      },
      prometheus+: {
        replicas: 1,
        resources+: {
          limits: { memory: '3000Mi' },
        },
        namespaces+: ['ingress-system', 'flux-system', 'rook-ceph', 'kyverno'],
      },
      alertmanager+: {
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
