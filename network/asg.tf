# aws_launch_template 과 aws_autoscaling_group 을 연결하는 리소스
# asg-tf

# #########################################################################
# 대상 그룹 생성
# #########################################################################

resource "aws_lb_target_group" "std11_nginx_tg" {
  name   = "${local.tag_header}nginx-tg"
  vpc_id = aws_vpc.std11_vpc.id

  port     = 80
  protocol = "HTTP"

  slow_start           = 30 # 30초 동안 속도를 조절하여 서버를 준비시킴
  deregistration_delay = 60 # 60초 동안 기존 서버를 준비시킴

  health_check {
    protocol = "HTTP"
    path     = "/"
    port     = "traffic-port" # 트래픽 포트 사용

    interval = 15 # 15초 마다 헬스 체크
    timeout  = 5  # 5초 만에 헬스 체크 응답이 없으면 서버를 준비시킴

    healthy_threshold   = 3 # 3번 연속 헬스 체크 성공하면 "정상"
    unhealthy_threshold = 3 # 3번 연속 헬스 체크 실패하면 "비정상"
  }
  tags = {
    Name = "${local.tag_header}nginx-tg"
  }
}

# #########################################################################
# 대상 그룹에 대상(인스턴스) 등록`
# #########################################################################

# resource "aws_lb_target_group_attachment" "std11_nginx_tg_attachment" {
#   target_group_arn = aws_lb_target_group.std11_nginx_tg.arn
#   target_id        = [for instance in aws_instance.std11_ec2_from_ami : instance.id]
#   port             = 80
# }

# #########################################################################
# 로드밸런서 생성
# #########################################################################

resource "aws_lb" "std11_nginx_alb" {
  name               = "${local.tag_header}nginx-alb"
  internal           = false
  load_balancer_type = "application" # 애플리케이션 로드밸런서
  security_groups    = [aws_security_group.std11_external_alb_sg.id]
  subnets            = [for subnet in aws_subnet.std11_public_subnet : subnet.id]
  tags = {
    Name = "${local.tag_header}nginx-alb"
  }
}
# #########################################################################
# 리스너 생성
# #########################################################################

resource "aws_lb_listener" "std11_nginx_alb_listener" {
  load_balancer_arn = aws_lb.std11_nginx_alb.arn
  port              = 80     # 사용자가 접근하는 포트
  protocol          = "HTTP" # 프로토콜
  default_action {
    type             = "forward"                              # 포워딩
    target_group_arn = aws_lb_target_group.std11_nginx_tg.arn # 대상 그룹
  }
  #   default_action {
  #     type = "fixed-response"
  #     fixed_response {
  #       content_type = "text/html"
  #       status_code  = "503"
  #       message_body = "<h1>돌아가라 대머리!</h1>"
  #     }
  #   }
}

# #########################################################################
# 리스너에 경로 규칙 추가
# #########################################################################

resource "aws_lb_listener_rule" "std11_nginx_alb_listener_rule" {
  listener_arn = aws_lb_listener.std11_nginx_alb_listener.arn
  priority     = 100 # 우선순위 100
  action {
    type             = "forward"                              # 포워딩
    target_group_arn = aws_lb_target_group.std11_nginx_tg.arn # 대상 그룹
  }
  condition {
    path_pattern {
      values = ["/api", "api/*"]
    }
  }
}

output "std11_nginx_alb_listener_arn" {
  value = aws_lb.std11_nginx_alb.arn
}

# 오토스케일링 그룹 생성
# #########################################################################

resource "aws_autoscaling_group" "std11_nginx_asg" {
  name             = "${local.tag_header}nginx-asg"
  min_size         = 1
  max_size         = 3
  desired_capacity = 2
  # 네트워크
  vpc_zone_identifier = [
    for subnet in aws_subnet.std11_public_subnet : subnet.id
  ]
  # 대상 그룹
  target_group_arns = [aws_lb_target_group.std11_nginx_tg.arn]

  launch_template {
    id      = aws_launch_template.std11_ec2_from_ami_launch_template.id
    version = "$Latest"
  }
  # 헬스 체크
  health_check_type         = "EC2" # EC2 인스턴스가 정상적으로 동작하는지 확인
  health_check_grace_period = 300   # 300초 동안 헬스 체크 실패하면 서버를 준비시킴

  # 태그
  tag {
    key                 = "Name"
    value               = "${local.tag_header}nginx-asg"
    propagate_at_launch = true
  }
}


# #########################################################################
# 오토스케일링 정책 생성 인스턴스 수량 조정의 기준
# #########################################################################

resource "aws_autoscaling_policy" "std11_nginx_asg_policy" {
  name                   = "${local.tag_header}nginx-asg-policy"
  autoscaling_group_name = aws_autoscaling_group.std11_nginx_asg.name

  policy_type = "TargetTrackingScaling" # 목표 값을 추적하는 정책

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization" # 평균 cpu 사용량 기준
    }
    target_value = 50 # 목표 cpu 사용량 (50~70% 권장)
  }
}


# #########################################################################
# asg 예약 정책
# #########################################################################

resource "aws_autoscaling_schedule" "std11_nginx_asg_schedule_out" {
  scheduled_action_name  = "${local.tag_header}nginx-asg-schedule"
  autoscaling_group_name = aws_autoscaling_group.std11_nginx_asg.name

  # 인스턴스 수량 조정
  min_size         = 2
  max_size         = 5
  desired_capacity = 4

  recurrence = "09 13 * * 1-5" # 매일 13시 0분 실행 (월~금)
  time_zone  = "Asia/Seoul"    # 서울 시간 최신 aws 프로바이더에서는 time_zone 가능
}

resource "aws_autoscaling_schedule" "std11_nginx_asg_schedule_in" {
  scheduled_action_name  = "${local.tag_header}nginx-asg-schedule-in"
  autoscaling_group_name = aws_autoscaling_group.std11_nginx_asg.name

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  recurrence = "11 13 * * 1-5" # 매일 18시 0분 실행 (월~금)
  time_zone  = "Asia/Seoul"    # 서울 시간 최신 aws 프로바이더에서는 time_zone 가능
}
