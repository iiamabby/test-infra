presubmits:
  kubernetes-sigs/cluster-api-provider-vsphere:
  - name: pull-cluster-api-provider-vsphere-apidiff-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    branches:
    - ^{{ $.branch }}$
    always_run: false
    # Run if go files, scripts or configuration changed (we use the same for all jobs for simplicity).
    run_if_changed: '^((apis|config|controllers|feature|hack|packaging|pkg|test|webhooks)/|Dockerfile|go\.mod|go\.sum|main\.go|Makefile)'
    optional: true
    decorate: true
    path_alias: sigs.k8s.io/cluster-api-provider-vsphere
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        command:
        - runner.sh
        args:
        - ./hack/ci-apidiff.sh
        resources:
          limits:
            cpu: 2
            memory: 4Gi
          requests:
            cpu: 2
            memory: 4Gi
    annotations:
      testgrid-dashboards: vmware-cluster-api-provider-vsphere, sig-cluster-lifecycle-cluster-api-provider-vsphere
      testgrid-tab-name: pr-apidiff-{{ ReplaceAll $.branch "." "-" }}
      description: Checks for API changes in the PR

  - name: pull-cluster-api-provider-vsphere-verify-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    branches:
    - ^{{ $.branch }}$
    labels:
      preset-dind-enabled: "true"
    always_run: true
    decorate: true
    path_alias: sigs.k8s.io/cluster-api-provider-vsphere
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        command:
        - runner.sh
        args:
        - make
        - verify
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
        resources:
          limits:
            cpu: 2
            memory: 4Gi
          requests:
            cpu: 2
            memory: 4Gi
    annotations:
      testgrid-dashboards: vmware-cluster-api-provider-vsphere, sig-cluster-lifecycle-cluster-api-provider-vsphere
      testgrid-tab-name: pr-verify-{{ ReplaceAll $.branch "." "-" }}

  - name: pull-cluster-api-provider-vsphere-test-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    branches:
    - ^{{ $.branch }}$
    always_run: false
    # Run if go files, scripts or configuration changed (we use the same for all jobs for simplicity).
    run_if_changed: '^((apis|config|controllers|feature|hack|packaging|pkg|test|webhooks)/|Dockerfile|go\.mod|go\.sum|main\.go|Makefile)'
    decorate: true
    path_alias: sigs.k8s.io/cluster-api-provider-vsphere
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        resources:
          limits:
            cpu: 2
            memory: 4Gi
          requests:
            cpu: 2
            memory: 4Gi
        command:
        - runner.sh
        args:
        - make
        - test-junit
    annotations:
      testgrid-dashboards: vmware-cluster-api-provider-vsphere, sig-cluster-lifecycle-cluster-api-provider-vsphere
      testgrid-tab-name: pr-test-{{ ReplaceAll $.branch "." "-" }}
      description: Runs unit tests

  - name: pull-cluster-api-provider-vsphere-test-integration-{{ ReplaceAll $.branch "." "-" }}
    cluster: eks-prow-build-cluster
    branches:
    - ^{{ $.branch }}$
    labels:
      preset-dind-enabled: "true"
      preset-kind-volume-mounts: "true"
    always_run: false
    # Run if go files, scripts or configuration changed (we use the same for all jobs for simplicity).
    run_if_changed: '^((apis|config|controllers|feature|hack|packaging|pkg|test|webhooks)/|Dockerfile|go\.mod|go\.sum|main\.go|Makefile)'
    decorate: true
    path_alias: sigs.k8s.io/cluster-api-provider-vsphere
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
          capabilities:
            add: ["NET_ADMIN"]
        resources:
          limits:
            cpu: 4
            memory: 6Gi
          requests:
            cpu: 4
            memory: 6Gi
        command:
        - runner.sh
        args:
        - make
        - test-integration
    annotations:
      testgrid-dashboards: vmware-cluster-api-provider-vsphere, sig-cluster-lifecycle-cluster-api-provider-vsphere
      testgrid-tab-name: pr-test-integration-{{ ReplaceAll $.branch "." "-" }}
      description: Runs integration tests

  - name: pull-cluster-api-provider-vsphere-e2e-{{ ReplaceAll $.branch "." "-" }}
    branches:
    - ^{{ $.branch }}$
    labels:
      preset-dind-enabled: "true"
      preset-cluster-api-provider-vsphere-e2e-config: "true"
      preset-cluster-api-provider-vsphere-gcs-creds: "true"
      preset-kind-volume-mounts: "true"
    always_run: false
    # Run if go files, scripts or configuration changed (we use the same for all jobs for simplicity).
    run_if_changed: '^((apis|config|controllers|feature|hack|packaging|pkg|test|webhooks)/|Dockerfile|go\.mod|go\.sum|main\.go|Makefile)'
    decorate: true
    path_alias: sigs.k8s.io/cluster-api-provider-vsphere
    max_concurrency: 3
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        command:
        - runner.sh
        args:
        - ./hack/e2e.sh
        env:
        - name: GINKGO_FOCUS
          value: "\\[PR-Blocking\\]"
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
          capabilities:
            add: ["NET_ADMIN"]
        resources:
          requests:
            cpu: "4000m"
            memory: "6Gi"
    annotations:
      testgrid-dashboards: vmware-cluster-api-provider-vsphere, sig-cluster-lifecycle-cluster-api-provider-vsphere
      testgrid-tab-name: pr-e2e-{{ ReplaceAll $.branch "." "-" }}
      description: Runs only PR Blocking e2e tests

  - name: pull-cluster-api-provider-vsphere-e2e-full-{{ ReplaceAll $.branch "." "-" }}
    branches:
    - ^{{ $.branch }}$
    labels:
      preset-dind-enabled: "true"
      preset-cluster-api-provider-vsphere-e2e-config: "true"
      preset-cluster-api-provider-vsphere-gcs-creds: "true"
      preset-kind-volume-mounts: "true"
    always_run: false
    decorate: true
    decoration_config:
      timeout: 180m
    path_alias: sigs.k8s.io/cluster-api-provider-vsphere
    max_concurrency: 3
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        command:
        - runner.sh
        args:
        - ./hack/e2e.sh
        env:
        - name: GINKGO_SKIP
          value: "\\[Conformance\\] \\[specialized-infra\\]"
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
          capabilities:
            add: ["NET_ADMIN"]
        resources:
          requests:
            cpu: "4000m"
            memory: "6Gi"
    annotations:
      testgrid-dashboards: vmware-cluster-api-provider-vsphere, sig-cluster-lifecycle-cluster-api-provider-vsphere
      testgrid-tab-name: pr-e2e-full-{{ ReplaceAll $.branch "." "-" }}
      description: Runs all e2e tests

  - name: pull-cluster-api-provider-vsphere-conformance-{{ ReplaceAll $.branch "." "-" }}
    branches:
    - ^{{ $.branch }}$
    labels:
      preset-dind-enabled: "true"
      preset-cluster-api-provider-vsphere-e2e-config: "true"
      preset-cluster-api-provider-vsphere-gcs-creds: "true"
      preset-kind-volume-mounts: "true"
    always_run: false
    decorate: true
    path_alias: sigs.k8s.io/cluster-api-provider-vsphere
    max_concurrency: 3
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        command:
        - runner.sh
        args:
        - ./hack/e2e.sh
        env:
        - name: GINKGO_FOCUS
{{- if eq $.branch "release-1.5" "release-1.6" "release-1.7" "release-1.8" }}
          value: "\\[Conformance\\]"
{{- else }}
          value: "testing K8S conformance \\[Conformance\\]"
{{- end }}
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
          capabilities:
            add: ["NET_ADMIN"]
        resources:
          requests:
            cpu: "4000m"
            memory: "6Gi"
    annotations:
      testgrid-dashboards: vmware-cluster-api-provider-vsphere, sig-cluster-lifecycle-cluster-api-provider-vsphere
      testgrid-tab-name: pr-conformance-{{ ReplaceAll $.branch "." "-" }}
      description: Runs conformance tests for CAPV
{{ if eq $.branch "release-1.5" "release-1.6" "release-1.7" "release-1.8" | not }}
  - name: pull-cluster-api-provider-vsphere-conformance-ci-latest-{{ ReplaceAll $.branch "." "-" }}
    branches:
    - ^{{ $.branch }}$
    labels:
      preset-dind-enabled: "true"
      preset-cluster-api-provider-vsphere-e2e-config: "true"
      preset-cluster-api-provider-vsphere-gcs-creds: "true"
      preset-kind-volume-mounts: "true"
    always_run: false
    decorate: true
    path_alias: sigs.k8s.io/cluster-api-provider-vsphere
    max_concurrency: 3
    spec:
      containers:
      - image: {{ $.config.TestImage }}
        command:
        - runner.sh
        args:
        - ./hack/e2e.sh
        env:
        - name: GINKGO_FOCUS
          value: "testing K8S conformance with K8S latest ci \\[Conformance\\]"
        # we need privileged mode in order to do docker in docker
        securityContext:
          privileged: true
          capabilities:
            add: ["NET_ADMIN"]
        resources:
          requests:
            cpu: "4000m"
            memory: "6Gi"
    annotations:
      testgrid-dashboards: vmware-cluster-api-provider-vsphere, sig-cluster-lifecycle-cluster-api-provider-vsphere
      testgrid-tab-name: pr-conformance-ci-latest-{{ ReplaceAll $.branch "." "-" }}
      description: Runs conformance tests with K8S ci latest for CAPV
{{ end }}