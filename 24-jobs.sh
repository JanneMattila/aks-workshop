####################
#    _       _     
#   (_) ___ | |__  
#   | |/ _ \| '_ \ 
#   | | (_) | |_) |
#  _/ |\___/|_.__/ 
# |__/        
####################

kubectl apply -f others/echo-job.yaml

kubectl get job
kubectl get pod

job_app_pod1=$(kubectl get pod -o name | tail -n 1)
echo $job_app_pod1

kubectl logs $job_app_pod1

#########################################
#                        _       _     
#   ___ _ __ ___  _ __  (_) ___ | |__  
#  / __| '__/ _ \| '_ \ | |/ _ \| '_ \ 
# | (__| | | (_) | | | || | (_) | |_) |
#  \___|_|  \___/|_| |_|/ |\___/|_.__/ 
#                     |__/         
#########################################

kubectl apply -f others/echoer-cronjob.yaml

kubectl get cronjob
kubectl get pod

cronjob_app_pod1=$(kubectl get pod -o name | tail -n 1)
echo $cronjob_app_pod1

kubectl logs $cronjob_app_pod1

kubectl delete -f others/echoer-cronjob.yaml

# QUESTION:
# ---------
# What is the difference between a cronjob and a job?
#
# https://kubernetes.io/docs/concepts/workloads/controllers/job/
# https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
#

# QUESTION:
# ---------
# Why do you see job pods in the output of "kubectl get pod"?
# How long do they stay there?
#
# Hint: Study properties of the job
kubectl describe job echo-job
kubectl describe cronjob echoer-cronjob
