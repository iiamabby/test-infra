presubmits:
  kubernetes-sigs/cluster-api:
  - name: pull-cluster-api-build-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    decorate: true
    path_alias: sigs.k8s.io/cluster-api
    always_run: true
    branches:
    # The script this job runs is not in all branches.
    - ^{{ $.branch }}$
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        command:
        - runner.sh
        - ./scripts/ci-build.sh
        resources:
          requests:
            cpu: 7300m
            memory: 9Gi
          limits:
            cpu: 7300m
            memory: 9Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-build-{{ ReplaceAll $.branch "." "-" }}
  - name: pull-cluster-api-apidiff-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    decorate: true
    path_alias: sigs.k8s.io/cluster-api
    optional: true
    branches:
    # The script this job runs is not in all branches.
    - ^{{ $.branch }}$
    run_if_changed: '^((api|bootstrap|cmd|config|controllers|controlplane|errors|exp|feature|hack|internal|scripts|test|util|webhooks|version)/|main\.go|go\.mod|go\.sum|Dockerfile|Makefile)'
    spec:
      containers:
      - command:
        - runner.sh
        - ./scripts/ci-apidiff.sh
        image: {{ $.config.TestImage }}
        resources:
          requests:
            cpu: 7300m
            memory: 9Gi
          limits:
            cpu: 7300m
            memory: 9Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-apidiff-{{ ReplaceAll $.branch "." "-" }}
  - name: pull-cluster-api-verify-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    decorate: true
    path_alias: sigs.k8s.io/cluster-api
    always_run: true
    labels:
      preset-dind-enabled: "true"
    branches:
    # The script this job runs is not in all branches.
    - ^{{ $.branch }}$
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        command:
        - "runner.sh"
        - ./scripts/ci-verify.sh
        resources:
          requests:
            cpu: 7300m
            memory: 9Gi
          limits:
            cpu: 7300m
            memory: 9Gi
        securityContext:
          privileged: true
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-verify-{{ ReplaceAll $.branch "." "-" }}
  - name: pull-cluster-api-test-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    decorate: true
    path_alias: sigs.k8s.io/cluster-api
    branches:
    # The script this job runs is not in all branches.
    - ^{{ $.branch }}$
    run_if_changed: '^((api|bootstrap|cmd|config|controllers|controlplane|errors|exp|feature|hack|internal|scripts|test|util|webhooks|version)/|main\.go|go\.mod|go\.sum|Dockerfile|Makefile)'
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        args:
        - runner.sh
        - ./scripts/ci-test.sh
        resources:
          requests:
            cpu: 7300m
            memory: 9Gi
          limits:
            cpu: 7300m
            memory: 9Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-test-{{ ReplaceAll $.branch "." "-" }}
  - name: pull-cluster-api-test-mink8s-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    decorate: true
    path_alias: sigs.k8s.io/cluster-api
    always_run: false
    branches:
    # The script this job runs is not in all branches.
    - ^{{ $.branch }}$
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        args:
        - runner.sh
        - ./scripts/ci-test.sh
        env:
        # This value determines the minimum Kubernetes
        # supported version for Cluster API management cluster
        # and can be found by referring to [Supported Kubernetes Version](https://cluster-api.sigs.k8s.io/reference/versions.html#supported-kubernetes-versions)
        # docs (look for minimum supported k8s version for management cluster, i.e N-3).
        #
        # To check the latest available envtest in Kubebuilder for the minor version we determined above, please
        # refer to https://github.com/kubernetes-sigs/kubebuilder/tree/tools-releases.
        - name: KUBEBUILDER_ENVTEST_KUBERNETES_VERSION
          value: "{{ $.config.KubebuilderEnvtestKubernetesVersion }}"
        resources:
          requests:
            cpu: 7300m
            memory: 9Gi
          limits:
            cpu: 7300m
            memory: 9Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-test-mink8s-{{ ReplaceAll $.branch "." "-" }}
{{- if eq $.branch "release-1.4" | not }}
  - name: pull-cluster-api-e2e-mink8s-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    labels:
      preset-dind-enabled: "true"
      preset-kind-volume-mounts: "true"
    decorate: true
    path_alias: sigs.k8s.io/cluster-api
    always_run: false
    branches:
    # The script this job runs is not in all branches.
    - ^{{ $.branch }}$
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        args:
        - runner.sh
        - ./scripts/ci-e2e.sh
        env:
        - name: GINKGO_SKIP
          value: "\\[Conformance\\] \\[K8s-Upgrade\\]|\\[IPv6\\]"
        # This value determines the minimum Kubernetes
        # supported version for Cluster API management cluster
        # and can be found by referring to [Supported Kubernetes Version](https://cluster-api.sigs.k8s.io/reference/versions.html#supported-kubernetes-versions)
        # docs (look for minimum supported k8s version for management cluster, i.e N-3).
        # Please also make sure to refer a version where a kindest/node image exists
        # for (see https://github.com/kubernetes-sigs/kind/releases/)
        - name: KUBERNETES_VERSION_MANAGEMENT
          value: "{{ $.config.KubernetesVersionManagement }}"
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
        resources:
          requests:
            cpu: 7300m
            memory: 32Gi
          limits:
            cpu: 7300m
            memory: 32Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-e2e-mink8s-{{ ReplaceAll $.branch "." "-" }}
{{- end }}
  - name: pull-cluster-api-e2e-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    labels:
      preset-dind-enabled: "true"
      preset-kind-volume-mounts: "true"
    decorate: true
    branches:
    # The script this job runs is not in all branches.
    - ^{{ $.branch }}$
    path_alias: sigs.k8s.io/cluster-api
    run_if_changed: '^((api|bootstrap|cmd|config|controllers|controlplane|errors|exp|feature|hack|internal|scripts|test|util|webhooks|version)/|main\.go|go\.mod|go\.sum|Dockerfile|Makefile)'
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        args:
          - runner.sh
          - "./scripts/ci-e2e.sh"
        env:
          - name: GINKGO_FOCUS
            value: "\\[PR-Blocking\\]"
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
        resources:
          requests:
            cpu: 7300m
            memory: 32Gi
          limits:
            cpu: 7300m
            memory: 32Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-e2e-{{ ReplaceAll $.branch "." "-" }}
{{- if eq $.branch "release-1.4" "release-1.5" }}
  - name: pull-cluster-api-e2e-informing-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    labels:
      preset-dind-enabled: "true"
      preset-kind-volume-mounts: "true"
    decorate: true
    optional: true
    branches:
      # The script this job runs is not in all branches.
      - ^{{ $.branch }}$
    path_alias: sigs.k8s.io/cluster-api
    run_if_changed: '^((api|bootstrap|cmd|config|controllers|controlplane|errors|exp|feature|hack|internal|scripts|test|util|webhooks|version)/|main\.go|go\.mod|go\.sum|Dockerfile|Makefile)'
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        args:
        - runner.sh
        - "./scripts/ci-e2e.sh"
        env:
        - name: GINKGO_FOCUS
          value: "\\[PR-Informing\\]"
{{- if eq $.branch "release-1.4" }}
        - name: GINKGO_SKIP
          value: "\\[IPv6\\]"
{{- end }}
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
        resources:
          requests:
            cpu: 7300m
            memory: 32Gi
          limits:
            cpu: 7300m
            memory: 32Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-e2e-informing-{{ ReplaceAll $.branch "." "-" }}
{{- end }}
{{- if eq $.branch "release-1.4" | not }}
  - name: pull-cluster-api-e2e-full-dualstack-and-ipv6-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    labels:
      preset-dind-enabled: "true"
      preset-kind-volume-mounts: "true"
    decorate: true
    always_run: false
    branches:
      # The script this job runs is not in all branches.
      - ^{{ $.branch }}$
    path_alias: sigs.k8s.io/cluster-api
    spec:
      containers:
        - image: {{ $.config.TestImage }}
          args:
            - runner.sh
            - "./scripts/ci-e2e.sh"
          env:
            # enable IPV6 in bootstrap image
            - name: "DOCKER_IN_DOCKER_IPV6_ENABLED"
              value: "true"
            # Since the PR-Blocking tests are run as part of the cluster-api-e2e job
            # and the upgrade tests are being run as part of the periodic upgrade jobs.
            # This jobs ends up running all the other tests in the E2E suite
            - name: GINKGO_SKIP
              value: "\\[PR-Blocking\\] \\[Conformance\\] \\[K8s-Upgrade\\]"
          # we need privileged mode in order to do docker in docker
          securityContext:
            privileged: true
          resources:
            requests:
              cpu: 7300m
              memory: 32Gi
            limits:
              cpu: 7300m
              memory: 32Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-e2e-full-dualstack-and-ipv6-{{ ReplaceAll $.branch "." "-" }}
{{ else }}
  - name: pull-cluster-api-e2e-informing-ipv6-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    labels:
      preset-dind-enabled: "true"
      preset-kind-volume-mounts: "true"
    decorate: true
    optional: true
    branches:
      # The script this job runs is not in all branches.
      - ^{{ $.branch }}$
    path_alias: sigs.k8s.io/cluster-api
    run_if_changed: '^((api|bootstrap|cmd|config|controllers|controlplane|errors|exp|feature|hack|internal|scripts|test|util|webhooks|version)/|main\.go|go\.mod|go\.sum|Dockerfile|Makefile)'
    spec:
      containers:
        - image: {{ $.config.TestImage }}
          args:
            - runner.sh
            - "./scripts/ci-e2e.sh"
          env:
            # enable IPV6 in bootstrap image
            - name: "DOCKER_IN_DOCKER_IPV6_ENABLED"
              value: "true"
            - name: GINKGO_FOCUS
              value: "\\[IPv6\\] \\[PR-Informing\\]"
            - name: IP_FAMILY
              value: "IPv6"
          # we need privileged mode in order to do docker in docker
          securityContext:
            privileged: true
          resources:
            requests:
              cpu: 7300m
              memory: 32Gi
            limits:
              cpu: 7300m
              memory: 32Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-e2e-informing-ipv6-{{ ReplaceAll $.branch "." "-" }}
{{- end }}
  - name: pull-cluster-api-e2e-full-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    labels:
      preset-dind-enabled: "true"
      preset-kind-volume-mounts: "true"
    decorate: true
    always_run: false
    branches:
    # The script this job runs is not in all branches.
    - ^{{ $.branch }}$
    path_alias: sigs.k8s.io/cluster-api
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        args:
          - runner.sh
          - "./scripts/ci-e2e.sh"
        env:
          # Since the PR-Blocking tests are run as part of the cluster-api-e2e job
          # and the upgrade tests are being run as part of the periodic upgrade jobs.
          # This jobs ends up running all the other tests in the E2E suite
          - name: GINKGO_SKIP
            value: "\\[PR-Blocking\\] \\[Conformance\\] \\[K8s-Upgrade\\]|\\[IPv6\\]"
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
        resources:
          requests:
            cpu: 7300m
            memory: 32Gi
          limits:
            cpu: 7300m
            memory: 32Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-e2e-full-{{ ReplaceAll $.branch "." "-" }}
  - name: pull-cluster-api-e2e-workload-upgrade-{{ ReplaceAll (last $.config.Upgrades).From "." "-" }}-{{ ReplaceAll (last $.config.Upgrades).To "." "-" }}-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    labels:
      preset-dind-enabled: "true"
      preset-kind-volume-mounts: "true"
    decorate: true
    always_run: false
    branches:
    # The script this job runs is not in all branches.
    - ^{{ $.branch }}$
    path_alias: sigs.k8s.io/cluster-api
    extra_refs:
    - org: kubernetes
      repo: kubernetes
      base_ref: master
      path_alias: k8s.io/kubernetes
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        args:
          - runner.sh
          - "./scripts/ci-e2e.sh"
        env:
          - name: ALWAYS_BUILD_KIND_IMAGES
            value: "true"
          - name: KUBERNETES_VERSION_UPGRADE_FROM
            value: "{{ index (index $.versions ((last $.config.Upgrades).From)) "k8sRelease" }}"
          - name: KUBERNETES_VERSION_UPGRADE_TO
            value: "{{ index (index $.versions ((last $.config.Upgrades).To)) "k8sRelease" }}"
          - name: ETCD_VERSION_UPGRADE_TO
            value: "{{ index (index $.versions ((last $.config.Upgrades).To)) "etcd" }}"
          - name: COREDNS_VERSION_UPGRADE_TO
            value: "{{ index (index $.versions ((last $.config.Upgrades).To)) "coreDNS" }}"
          - name: GINKGO_FOCUS
            value: "\\[K8s-Upgrade\\]"
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
        resources:
          requests:
            cpu: 7300m
            memory: 32Gi
          limits:
            cpu: 7300m
            memory: 32Gi
    annotations:
      testgrid-dashboards: sig-cluster-lifecycle-cluster-api{{ if eq $.branch "main" | not -}}{{ TrimPrefix $.branch "release" }}{{- end }}
      testgrid-tab-name: capi-pr-e2e-{{ ReplaceAll $.branch "." "-" }}-{{ ReplaceAll (last $.config.Upgrades).From "." "-" }}-{{ ReplaceAll (last $.config.Upgrades).To "." "-" }}
