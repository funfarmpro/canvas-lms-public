# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class QuestionBanksApiController < ApplicationController
  before_action :require_context

  # @API List questions in a classic question bank
  #
  # Returns paginated classic question bank questions in the same structure as
  # the web JSON endpoint, including assessment_question.question_data with
  # answers[].weight and points_possible.
  #
  # @argument inherited [Boolean]
  #   Search inherited banks for this context as well.
  #
  # @returns {"pages": Integer, "questions": [AssessmentQuestion]}
  def questions
    find_bank(params[:question_bank_id], params[:inherited] == "1") do
      questions = @bank.assessment_questions.active
      questions_url = request.original_url
      questions = Api.paginate(questions, self, questions_url, default_per_page: 50)
      render json: { pages: questions.total_pages, questions: questions }
    end
  end
end
